// Carga las variables de entorno del archivo .env al inicio de todo
require('dotenv').config();

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const GitHubStrategy = require('passport-github2').Strategy;
const session = require('express-session');

const app = express();
const PORT = process.env.PORT || 3006;

// --- Configuración de la Base de Datos (Forma Segura) ---
const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE
};

// --- Middlewares ---
app.use(cors());
app.use(express.json());

// Configuración de Sesiones
app.use(session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false } // Para desarrollo local. En producción con HTTPS, cambiar a true.
}));

// Inicializar Passport
app.use(passport.initialize());
app.use(passport.session());

// --- Lógica de Passport ---

passport.serializeUser((user, done) => {
    done(null, user.user_id);
});

passport.deserializeUser(async(id, done) => {
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        const [rows] = await connection.execute('SELECT * FROM Users WHERE user_id = ?', [id]);
        done(null, rows[0] || null);
    } catch (err) {
        done(err, null);
    } finally {
        if (connection) await connection.end();
    }
});

// Estrategia de Google
passport.use(new GoogleStrategy({
        clientID: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        callbackURL: "/auth/google/callback"
    },
    async(accessToken, refreshToken, profile, done) => {
        let connection;
        try {
            connection = await mysql.createConnection(dbConfig);
            const email = profile.emails[0].value;
            const [existingUser] = await connection.execute('SELECT * FROM Users WHERE email = ?', [email]);

            if (existingUser.length > 0) {
                return done(null, existingUser[0]);
            }

            const [newUser] = await connection.execute('INSERT INTO Users (name, email) VALUES (?, ?)', [profile.displayName, email]);
            const [user] = await connection.execute('SELECT * FROM Users WHERE user_id = ?', [newUser.insertId]);
            return done(null, user[0]);
        } catch (err) {
            return done(err, false);
        } finally {
            if (connection) await connection.end();
        }
    }
));

// Estrategia de GitHub
passport.use(new GitHubStrategy({
        clientID: process.env.GITHUB_CLIENT_ID,
        clientSecret: process.env.GITHUB_CLIENT_SECRET,
        callbackURL: "/auth/github/callback",
        scope: ['user:email']
    },
    async(accessToken, refreshToken, profile, done) => {
        let connection;
        try {
            const email = profile.emails && profile.emails.length > 0 ? profile.emails[0].value : null;
            if (!email) {
                return done(new Error('No se pudo obtener el email de GitHub.'), null);
            }
            connection = await mysql.createConnection(dbConfig);
            const [existingUser] = await connection.execute('SELECT * FROM Users WHERE email = ?', [email]);

            if (existingUser.length > 0) {
                return done(null, existingUser[0]);
            }

            const [newUser] = await connection.execute('INSERT INTO Users (name, email) VALUES (?, ?)', [profile.displayName || profile.username, email]);
            const [user] = await connection.execute('SELECT * FROM Users WHERE user_id = ?', [newUser.insertId]);
            return done(null, user[0]);
        } catch (err) {
            return done(err, false);
        } finally {
            if (connection) await connection.end();
        }
    }
));


// --- Rutas de Autenticación ---

app.get('/auth/google', passport.authenticate('google', { scope: ['profile', 'email'] }));
app.get('/auth/google/callback', passport.authenticate('google', { failureRedirect: '/inicio_sesion/inicio.html' }), (req, res) => {
    res.redirect('/settings/settings.html');
});

app.get('/auth/github', passport.authenticate('github', { scope: ['user:email'] }));
app.get('/auth/github/callback', passport.authenticate('github', { failureRedirect: '/inicio_sesion/inicio.html' }), (req, res) => {
    res.redirect('/settings/settings.html');
});

// --- Otras Rutas de la API ---

// Endpoint para recibir reportes de incidentes
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

// (Aquí puedes añadir el resto de tus rutas, como /api/users, /api/articles, etc.)


// --- Iniciar el Servidor ---
app.listen(PORT, () => {
    console.log(`Servidor escuchando en el puerto ${PORT}`);
});