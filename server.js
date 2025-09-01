const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();
const port = 3006;

// --- Configuración de la Base de Datos ---
// Reemplaza con la contraseña que estableciste. Si no pusiste, déjala como ''.
const dbConfig = {
    host: '127.0.0.1',
    user: 'root',
    port: 3006,
    password: '011919',
    database: 'helpxion_db'
};

// --- Middlewares ---
// Habilita CORS para permitir peticiones desde tu frontend
app.use(cors());
// Permite que Express entienda datos en formato JSON
app.use(express.json());


// --- Rutas de la API (Endpoints) ---

// Endpoint para obtener un artículo y sus secciones por su 'slug' (ej: 'red-team')
app.get('/api/articles/:slug', async(req, res) => {
    const slug = req.params.slug;
    let connection;

    try {
        // Conectamos a la base de datos
        connection = await mysql.createConnection(dbConfig);

        // 1. Buscamos el artículo principal
        const [articleRows] = await connection.execute('SELECT * FROM Articles WHERE slug = ?', [slug]);

        if (articleRows.length === 0) {
            return res.status(404).json({ message: 'Artículo no encontrado' });
        }

        const article = articleRows[0];

        // 2. Buscamos todas sus secciones, ordenadas
        const [sectionRows] = await connection.execute(
            'SELECT * FROM ArticleSections WHERE article_id = ? ORDER BY display_order ASC', [article.article_id]
        );

        // 3. Combinamos el artículo con sus secciones
        article.sections = sectionRows;

        // 4. Enviamos la respuesta completa en formato JSON
        res.json(article);

    } catch (error) {
        console.error('Error al conectar o consultar la base de datos:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    } finally {
        if (connection) await connection.end(); // Cerramos la conexión
    }
});

// Endpoint para crear un nuevo usuario (guardar credenciales)
app.post('/api/users', async(req, res) => {
    const { name, email } = req.body;

    // Validación simple de los datos de entrada
    if (!name || !email) {
        return res.status(400).json({ message: 'El nombre y el correo electrónico son obligatorios.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        // El '?' previene inyección SQL
        const query = 'INSERT INTO Users (name, email) VALUES (?, ?)';
        const [result] = await connection.execute(query, [name, email]);

        // Enviamos una respuesta exitosa con el ID del nuevo usuario
        res.status(201).json({
            message: 'Usuario creado exitosamente',
            userId: result.insertId
        });

    } catch (error) {
        // Manejo de errores específicos de la base de datos
        if (error.code === 'ER_DUP_ENTRY') {
            // El correo ya existe (porque la columna email es UNIQUE)
            return res.status(409).json({ message: 'El correo electrónico ya está registrado.' });
        }

        console.error('Error al crear el usuario:', error);
        res.status(500).json({ message: 'Error interno del servidor al crear el usuario.' });
    } finally {
        if (connection) await connection.end();
    }
});

// Endpoint para obtener los datos de un usuario por su ID
app.get('/api/users/:id', async(req, res) => {
    const { id } = req.params;
    let connection;

    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute('SELECT user_id, name, email, phone FROM Users WHERE user_id = ?', [id]);

        if (rows.length === 0) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        res.json(rows[0]);
    } catch (error) {
        console.error('Error al obtener el usuario:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    } finally {
        if (connection) await connection.end();
    }
});

// Endpoint para actualizar los datos de un usuario
app.put('/api/users/:id', async(req, res) => {
    const { id } = req.params;
    const { name, email, phone } = req.body;

    if (!name || !email) {
        return res.status(400).json({ message: 'El nombre y el correo son obligatorios.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const query = 'UPDATE Users SET name = ?, email = ?, phone = ? WHERE user_id = ?';
        const [result] = await connection.execute(query, [name, email, phone, id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Usuario no encontrado para actualizar.' });
        }

        res.json({ message: 'Perfil actualizado exitosamente.' });

    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ message: 'El correo electrónico ya está en uso por otra cuenta.' });
        }
        console.error('Error al actualizar el usuario:', error);
        res.status(500).json({ message: 'Error interno del servidor al actualizar el perfil.' });
    } finally {
        if (connection) await connection.end();
    }
});

// --- Iniciar el Servidor ---
app.listen(port, () => {
    console.log(`Servidor escuchando en el puerto ${PORT}`);
});