-- =================================================================
--  Esquema de Base de Datos para Helpxion Fortsent
-- =================================================================
-- Este script crea la estructura de la base de datos y la puebla
-- con los datos iniciales extraídos de los archivos del proyecto.
-- =================================================================

-- Desactivar la verificación de claves foráneas temporalmente para la creación
SET FOREIGN_KEY_CHECKS=0;

--
-- Tabla: Articles
-- Almacena el contenido principal de las páginas de servicios (Red Team, Blue Team).
--
DROP TABLE IF EXISTS `Articles`;
CREATE TABLE `Articles` (
  `article_id` INT AUTO_INCREMENT PRIMARY KEY,
  `slug` VARCHAR(100) NOT NULL UNIQUE,
  `title` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT='Almacena los artículos o descripciones de servicios.';

--
-- Tabla: ArticleSections
-- Almacena las secciones individuales de cada artículo.
--
DROP TABLE IF EXISTS `ArticleSections`;
CREATE TABLE `ArticleSections` (
  `section_id` INT AUTO_INCREMENT PRIMARY KEY,
  `article_id` INT NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `content` TEXT NOT NULL,
  `image_url` VARCHAR(512),
  `image_alt_text` VARCHAR(512),
  `display_order` INT NOT NULL,
  FOREIGN KEY (`article_id`) REFERENCES `Articles`(`article_id`) ON DELETE CASCADE,
  INDEX `idx_article_id` (`article_id`)
) COMMENT='Secciones de contenido para cada artículo.';

--
-- Tabla: Plans
-- Define los diferentes planes de suscripción disponibles.
--
DROP TABLE IF EXISTS `Plans`;
CREATE TABLE `Plans` (
  `plan_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL UNIQUE,
  `price_monthly` DECIMAL(10, 2),
  `price_semiannually` DECIMAL(10, 2),
  `price_annually` DECIMAL(10, 2),
  `currency` VARCHAR(3) DEFAULT 'COP',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `stripe_monthly_id` VARCHAR(255) UNIQUE,
  `stripe_semiannually_id` VARCHAR(255) UNIQUE,
  `stripe_annually_id` VARCHAR(255) UNIQUE
) COMMENT='Planes de suscripción y sus precios.';

--
-- Tabla: PlanBenefits
-- Lista los beneficios asociados a cada plan.
--
DROP TABLE IF EXISTS `PlanBenefits`;
CREATE TABLE `PlanBenefits` (
  `benefit_id` INT AUTO_INCREMENT PRIMARY KEY,
  `plan_id` INT NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  FOREIGN KEY (`plan_id`) REFERENCES `Plans`(`plan_id`) ON DELETE CASCADE,
  INDEX `idx_plan_id_benefits` (`plan_id`)
) COMMENT='Beneficios específicos de cada plan.';

--
-- Tabla: Users
-- Almacena la información de los clientes.
--
DROP TABLE IF EXISTS `Users`;
CREATE TABLE `Users` (
  `user_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL UNIQUE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT='Información de los usuarios registrados.';

--
-- Tabla: Subscriptions
-- Vincula a los usuarios con los planes que han contratado.
--
DROP TABLE IF EXISTS `Subscriptions`;
CREATE TABLE `Subscriptions` (
  `subscription_id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `plan_id` INT NOT NULL,
  `start_date` DATETIME NOT NULL,
  `end_date` DATETIME,
  `status` ENUM('active', 'canceled', 'expired') NOT NULL,
  `billing_cycle` ENUM('monthly', 'semiannually', 'annually') NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `Users`(`user_id`),
  FOREIGN KEY (`plan_id`) REFERENCES `Plans`(`plan_id`),
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_plan_id_subscriptions` (`plan_id`),
  INDEX `idx_subscription_status` (`status`)
) COMMENT='Suscripciones activas de los usuarios a los planes.';

--
-- Tabla: Payments
-- Registra las transacciones de pago.
--
DROP TABLE IF EXISTS `Payments`;
CREATE TABLE `Payments` (
  `payment_id` INT AUTO_INCREMENT PRIMARY KEY,
  `subscription_id` INT NOT NULL,
  `stripe_transaction_id` VARCHAR(255) UNIQUE,
  `amount` DECIMAL(10, 2) NOT NULL,
  `currency` VARCHAR(3) NOT NULL,
  `payment_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `status` ENUM('succeeded', 'pending', 'failed') NOT NULL,
  FOREIGN KEY (`subscription_id`) REFERENCES `Subscriptions`(`subscription_id`),
  INDEX `idx_subscription_id` (`subscription_id`),
  INDEX `idx_payment_status` (`status`)
) COMMENT='Historial de pagos de las suscripciones.';

-- Reactivar la verificación de claves foráneas
SET FOREIGN_KEY_CHECKS=1;


-- =================================================================
--  Poblando la Base de Datos con Datos Iniciales
-- =================================================================

-- Insertar Artículos
INSERT INTO `Articles` (`slug`, `title`) VALUES
('blue-team', 'Blue Team'),
('red-team', 'Red Team');

-- Insertar Secciones del Artículo "Blue Team"
INSERT INTO `ArticleSections` (`article_id`, `title`, `content`, `image_url`, `image_alt_text`, `display_order`) VALUES
(1, '¿Qué es un Blue Team?', 'Un <strong>Blue Team</strong> es el equipo interno de seguridad responsable de defender a una organización contra todo tipo de ciberamenazas. Son la primera y última línea de defensa, encargados de mantener y mejorar la postura de seguridad de la empresa de manera continua. Su trabajo es proactivo y reactivo: por un lado, fortalecen la infraestructura para prevenir ataques (hardening); por otro, monitorean constantemente los sistemas en busca de actividad maliciosa y responden de inmediato cuando se detecta un incidente.', 'https://images.pexels.com/photos/2007647/pexels-photo-2007647.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Analista de seguridad monitoreando múltiples pantallas con gráficos y datos, representando la vigilancia constante del Blue Team.', 1),
(1, 'Objetivo Principal', 'El objetivo primordial del Blue Team es garantizar la <strong>Confidencialidad, Integridad y Disponibilidad (la triada CIA)</strong> de los activos de información de la empresa. Esto implica minimizar la superficie de ataque, reducir el tiempo de detección de amenazas (MTTD) y acelerar el tiempo de respuesta y recuperación ante un incidente (MTTR). En resumen, su misión es hacer que sea lo más difícil y costoso posible para un atacante tener éxito.', 'https://images.pexels.com/photos/5935791/pexels-photo-5935791.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Un candado digital sobre un fondo de código binario, representando la protección de la confidencialidad e integridad de los datos.', 2),
(1, 'Fases de la Defensa', 'El trabajo del Blue Team sigue un ciclo continuo basado en marcos como el NIST Cybersecurity Framework: <strong>Identificar</strong>, <strong>Proteger</strong>, <strong>Detectar</strong>, <strong>Responder</strong> y <strong>Recuperar</strong>. Este ciclo asegura un enfoque estructurado desde la evaluación de riesgos hasta la restauración de operaciones y el aprendizaje post-incidente para fortalecer las defensas futuras.', 'https://images.pexels.com/photos/3184292/pexels-photo-3184292.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Un equipo diverso planificando una estrategia sobre una mesa con diagramas, simbolizando las fases estructuradas de la defensa.', 3),
(1, 'El Rol del SOC (Security Operations Center)', 'El Blue Team a menudo opera dentro de un <strong>Centro de Operaciones de Seguridad (SOC)</strong>. El SOC es el centro neurálgico de la defensa, donde los analistas utilizan una variedad de herramientas para centralizar y correlacionar alertas de seguridad de toda la organización. Es un entorno de alta presión que opera 24/7 para garantizar una vigilancia constante y una capacidad de respuesta inmediata.', 'https://images.pexels.com/photos/7988086/pexels-photo-7988086.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Una sala de control con múltiples pantallas mostrando datos y gráficos en tiempo real, representando un Centro de Operaciones de Seguridad.', 4),
(1, 'Habilidades Clave', 'Los profesionales del Blue Team deben tener un conocimiento profundo de <strong>sistemas operativos, redes y arquitecturas de seguridad</strong>. Son expertos en análisis de logs, forense digital e inteligencia de amenazas (Threat Intelligence). A diferencia de la mentalidad ofensiva, deben ser meticulosos, pacientes y tener una gran capacidad de análisis para descubrir la narrativa completa de un ataque.', 'https://images.pexels.com/photos/5439473/pexels-photo-5439473.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Un analista forense examinando datos en una tableta, representando la meticulosidad y el conocimiento técnico.', 5),
(1, 'Herramientas Defensivas Comunes', 'El arsenal del Blue Team se centra en la visibilidad y el control. La herramienta principal es el <strong>SIEM</strong>, que agrega y correlaciona logs. Otras herramientas clave incluyen <strong>EDR</strong> para monitorear endpoints, <strong>IDS/IPS</strong> para la red, y plataformas de inteligencia de amenazas para mantenerse al día sobre nuevos adversarios.', 'https://images.pexels.com/photos/3861958/pexels-photo-3861958.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Una persona interactuando con un dashboard de seguridad avanzado en una pantalla grande, simbolizando las herramientas de defensa.', 6),
(1, 'El Ciclo de Mejora Continua', 'La ciberseguridad no es un estado, es un proceso. El Blue Team es el motor de este proceso. Cada incidente es una oportunidad de aprendizaje. Las lecciones aprendidas se utilizan para <strong>ajustar configuraciones, crear nuevas reglas de detección y mejorar los procedimientos de respuesta</strong>. Este ciclo constante de retroalimentación y mejora es lo que permite a una organización adaptarse y evolucionar.', 'https://images.pexels.com/photos/5926382/pexels-photo-5926382.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Un desarrollador revisando código, lo que representa el proceso de aprendizaje y mejora continua después de un incidente.', 7);

-- Insertar Secciones del Artículo "Red Team"
INSERT INTO `ArticleSections` (`article_id`, `title`, `content`, `image_url`, `image_alt_text`, `display_order`) VALUES
(2, '¿Qué es un Red Team?', 'Un <strong>Red Team</strong> opera como un adversario simulado, adoptando la mentalidad, tácticas y herramientas de atacantes reales. Su propósito es realizar una evaluación de seguridad integral y realista, poniendo a prueba la capacidad de la organización para <strong>detectar, responder y recuperarse</strong> de un ciberataque sofisticado. Actúan como un "abogado del diablo" para la seguridad, desafiando las suposiciones y revelando debilidades en el ecosistema completo: personas, procesos y tecnología.', 'https://images.pexels.com/photos/5380664/pexels-photo-5380664.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Persona con capucha en una habitación oscura, representando a un adversario cibernético.', 1),
(2, 'Objetivo Principal', 'El objetivo final es mejorar la resiliencia. Esto implica identificar brechas que los escaneos no ven, evaluar la efectividad del Blue Team en tiempo real, y probar la conciencia de seguridad del personal. En esencia, un Red Team busca responder a la pregunta: <strong>"¿Qué tan seguros somos realmente contra un atacante motivado y hábil?"</strong>, proporcionando una medida tangible del riesgo y justificando la inversión en seguridad.', 'https://images.pexels.com/photos/3184296/pexels-photo-3184296.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Piezas de ajedrez en un tablero, simbolizando la estrategia y el pensamiento táctico del Red Team.', 2),
(2, 'Metodología de Ataque', 'Los Red Teams emulan la "Cyber Kill Chain" o marcos como MITRE ATT&CK®. Las fases incluyen: <strong>Reconocimiento</strong> (recopilación de información pública), <strong>Armamento y Entrega</strong> (creación de malware y envío por phishing), <strong>Explotación</strong> (ganar acceso), <strong>Instalación y C2</strong> (establecer persistencia y comunicación), y <strong>Acciones sobre Objetivos</strong> (moverse lateralmente, escalar privilegios y exfiltrar datos simulados).', 'https://images.pexels.com/photos/7107538/pexels-photo-7107538.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Una cadena de bloques de dominó a punto de caer, representando la cadena de ataque o Kill Chain.', 3),
(2, 'Red Team vs. Blue Team', 'Es la dinámica de atacante contra defensor. El <strong>Red Team</strong> intenta penetrar sin ser detectado, mientras el <strong>Blue Team</strong> usa sus herramientas para defenderse. La verdadera magia ocurre en el "debriefing" post-ejercicio, donde ambos equipos colaboran. Este proceso, llamado <strong>"Purple Teaming"</strong>, es donde se genera el mayor valor, ya que el Blue Team aprende nuevas técnicas de ataque y el Red Team entiende mejor las defensas.', 'https://images.pexels.com/photos/7034493/pexels-photo-7034493.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Dos personas jugando al ajedrez, representando la confrontación táctica entre el equipo rojo (ataque) y el equipo azul (defensa).', 4),
(2, 'Habilidades Clave', 'Un operador de Red Team es un profesional multidisciplinario. Requiere un dominio técnico en <strong>hacking ético y evasión de defensas</strong>. Pero igualmente crucial es la <strong>creatividad</strong> para idear vectores de ataque no convencionales y la <strong>psicología</strong> para ejecutar campañas de ingeniería social convincentes. También deben ser excelentes comunicadores para traducir hallazgos técnicos en riesgos de negocio.', 'https://images.pexels.com/photos/3184338/pexels-photo-3184338.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Un equipo diverso colaborando en una lluvia de ideas, simbolizando la creatividad y el pensamiento lateral.', 5),
(2, 'Diferencia con Pentesting', 'Un <strong>Pentest</strong> es como buscar todas las puertas y ventanas abiertas de una casa (amplitud). Un ejercicio de <strong>Red Team</strong> es como simular a un ladrón que encuentra una ventana, entra sigilosamente, evita las alarmas y llega a la caja fuerte (profundidad y sigilo). El Pentest busca reportar la mayor cantidad de vulnerabilidades posible; el Red Team simula un adversario real con un objetivo específico para probar las capacidades de respuesta.', 'https://images.pexels.com/photos/373543/pexels-photo-373543.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Una persona mirando a través de una lupa un código, representando la búsqueda amplia de fallos del pentesting.', 6),
(2, 'Reporte Final y Remediación', 'El entregable final es un informe ejecutivo y técnico. El informe ejecutivo traduce el riesgo técnico a un lenguaje de negocio. El informe técnico detalla la <strong>cadena de ataque completa (TTPs)</strong>, con recomendaciones no solo para parchar vulnerabilidades (tácticas), sino para mejorar procesos, arquitecturas y estrategias de detección a largo plazo (estratégicas).', 'https://images.pexels.com/photos/3184418/pexels-photo-3184418.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Un equipo de negocios revisando un informe con gráficos y datos, representando el entregable final de un ejercicio de Red Team.', 7);

-- Insertar Planes de Pago
INSERT INTO `Plans` (`name`, `price_monthly`, `price_semiannually`, `price_annually`, `stripe_monthly_id`, `stripe_semiannually_id`, `stripe_annually_id`) VALUES
('Protección Personal', 40000.00, 199000.00, 420000.00, 'test_7sYbJ07WDa8TgTD7Sw3sI00', 'test_28E00i5OvftdfPz1u83sI04', 'test_00weVc2Cj6WH6eZ3Cg3sI02'),
('Empresa Pequeña', 400000.00, 2200000.00, 4500000.00, 'test_4gM00i4KrbcXdHr7Sw3sI03', 'test_placeholder_business_6m', 'test_8x2dR890H80L9rbgp23sI05');
-- NOTA: El ID de Stripe para el plan semestral de "Empresa Pequeña" era un duplicado en el HTML. Se ha usado un placeholder.
-- NOTA: El precio semestral de "Empresa Pequeña" se ha estimado, ya que el HTML contenía un valor inconsistente.

-- Insertar Beneficios del Plan "Protección Personal"
INSERT INTO `PlanBenefits` (`plan_id`, `description`) VALUES
(1, 'Monitoreo de identidad'),
(1, 'CyberShield personal'),
(1, 'VPN Premium'),
(1, 'Asesoría básica 24/7'),
(1, 'Evaluación anual');

-- Insertar Beneficios del Plan "Empresa Pequeña"
INSERT INTO `PlanBenefits` (`plan_id`, `description`) VALUES
(2, 'Todo en Personal Plus'),
(2, 'Pentest anual'),
(2, 'Monitoreo de red básico'),
(2, 'Respuesta rápida a incidentes'),
(2, 'Hasta 25 empleados');

-- Ejemplo de cómo insertar un usuario (descomentar para probar)
-- INSERT INTO `Users` (`name`, `email`) VALUES ('Santiago Prueba', 'santiago@example.com');

-- Ejemplo de cómo insertar una suscripción (descomentar para probar)
-- INSERT INTO `Subscriptions` (`user_id`, `plan_id`, `start_date`, `status`, `billing_cycle`) VALUES (1, 1, NOW(), 'active', 'monthly');

COMMIT;
