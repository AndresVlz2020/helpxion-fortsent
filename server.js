const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();

// --- Configuración de la Base de Datos ---
// Apunta a tu base de datos local
const dbConfig = {
    host: '127.0.0.1',
    user: 'root',
    password: '011919', // O la contraseña de tu base de datos local
    database: 'helpxion_db'
};

const PORT = process.env.PORT || 3006;

// --- Middlewares ---
app.use(cors());
app.use(express.json());


// --- Rutas de la API (Endpoints) ---

// Endpoint para obtener un artículo y sus secciones por su 'slug'
app.get('/api/articles/:slug', async(req, res) => {
    const slug = req.params.slug;
    let connection;

    try {
        connection = await mysql.createConnection(dbConfig);
        const [articleRows] = await connection.execute('SELECT * FROM Articles WHERE slug = ?', [slug]);

        if (articleRows.length === 0) {
            return res.status(404).json({ message: 'Artículo no encontrado' });
        }
        const article = articleRows[0];
        const [sectionRows] = await connection.execute(
            'SELECT * FROM ArticleSections WHERE article_id = ? ORDER BY display_order ASC', [article.article_id]
        );
        article.sections = sectionRows;
        res.json(article);

    } catch (error) {
        console.error('Error al consultar la base de datos:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    } finally {
        if (connection) await connection.end();
    }
});

// Endpoint para crear un nuevo usuario
app.post('/api/users', async(req, res) => {
    const { name, email } = req.body;
    if (!name || !email) {
        return res.status(400).json({ message: 'El nombre y el correo electrónico son obligatorios.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const query = 'INSERT INTO Users (name, email) VALUES (?, ?)';
        const [result] = await connection.execute(query, [name, email]);
        res.status(201).json({
            message: 'Usuario creado exitosamente',
            userId: result.insertId
        });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
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

// --- Endpoint para recibir reportes de incidentes ---
app.post('/api/reports', async(req, res) => {
    const { incidentType, severity, description, wantsFollowUp, contactMethod } = req.body;

    if (!incidentType || !severity || !description) {
        return res.status(400).json({ message: 'Tipo de incidente, gravedad y descripción son obligatorios.' });
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const query = 'INSERT INTO Reports (incident_type, severity, description, wants_follow_up, contact_method) VALUES (?, ?, ?, ?, ?)';

        const followUpValue = wantsFollowUp ? 1 : 0;

        const [result] = await connection.execute(query, [incidentType, severity, description, followUpValue, contactMethod]);

        res.status(201).json({
            message: 'Reporte enviado exitosamente. Gracias por tu contribución.',
            reportId: result.insertId
        });

    } catch (error) {
        console.error('Error al guardar el reporte:', error);
        res.status(500).json({ message: 'Error interno del servidor al procesar el reporte.' });
    } finally {
        if (connection) await connection.end();
    }
});


// --- Iniciar el Servidor ---
app.listen(PORT, () => {
    console.log(`Servidor escuchando en el puerto ${PORT}`);
});