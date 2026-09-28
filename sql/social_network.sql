-- =====================================================================
--  Social Network DB - Rede social para programadores
--  SGBD: MySQL 8.0+
--  Disciplina: Laboratório de Programação
-- =====================================================================

DROP DATABASE IF EXISTS social_network;
CREATE DATABASE social_network
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE social_network;

-- ---------------------------------------------------------------------
-- 1. USUÁRIOS (informações pessoais e profissionais) - Requisito 1
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    -- Dados pessoais
    name            VARCHAR(100)  NOT NULL,
    username        VARCHAR(50)   NOT NULL UNIQUE,
    email           VARCHAR(150)  NOT NULL UNIQUE,
    password_hash   VARCHAR(255)  NOT NULL,
    birth_date      DATE,
    city            VARCHAR(100),
    country         VARCHAR(100),
    bio             TEXT,
    profile_picture VARCHAR(255),
    -- Dados profissionais
    job_title       VARCHAR(100),
    company         VARCHAR(100),
    experience_years INT DEFAULT 0,
    github_url      VARCHAR(255),
    linkedin_url    VARCHAR(255),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_users_experience CHECK (experience_years >= 0)
);

-- ---------------------------------------------------------------------
-- 7. GRUPOS TEMÁTICOS (linguagens / tecnologias) - Requisito 7
--    (criada antes de posts porque posts referencia grupos)
-- ---------------------------------------------------------------------
CREATE TABLE tech_groups (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    topic       VARCHAR(50)  NOT NULL,          -- ex: 'Python', 'React', 'DevOps'
    created_by  INT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_groups_creator FOREIGN KEY (created_by)
        REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE group_members (
    group_id  INT NOT NULL,
    user_id   INT NOT NULL,
    role      ENUM('member', 'moderator', 'admin') DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id),
    CONSTRAINT fk_gm_group FOREIGN KEY (group_id) REFERENCES tech_groups(id) ON DELETE CASCADE,
    CONSTRAINT fk_gm_user  FOREIGN KEY (user_id)  REFERENCES users(id)       ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- 2. POSTAGENS (texto e link) - Requisitos 2 e 8
--    group_id NULL  -> post no perfil do usuário
--    group_id != NULL -> post feito dentro de um grupo
-- ---------------------------------------------------------------------
CREATE TABLE posts (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT  NOT NULL,
    group_id   INT  NULL,
    content    TEXT NOT NULL,
    link_url   VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_posts_user  FOREIGN KEY (user_id)  REFERENCES users(id)       ON DELETE CASCADE,
    CONSTRAINT fk_posts_group FOREIGN KEY (group_id) REFERENCES tech_groups(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- 3. COMENTÁRIOS - Requisito 3
-- ---------------------------------------------------------------------
CREATE TABLE comments (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    post_id    INT  NOT NULL,
    user_id    INT  NOT NULL,
    content    TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comments_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- 3. CURTIDAS (em posts OU comentários) - Requisito 3
--    Exatamente um dos campos post_id / comment_id deve ser preenchido.
-- ---------------------------------------------------------------------
CREATE TABLE likes (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT NOT NULL,
    post_id    INT NULL,
    comment_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_likes_user    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
    CONSTRAINT fk_likes_post    FOREIGN KEY (post_id)    REFERENCES posts(id)    ON DELETE CASCADE,
    CONSTRAINT fk_likes_comment FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    CONSTRAINT uq_like_post    UNIQUE (user_id, post_id),
    CONSTRAINT uq_like_comment UNIQUE (user_id, comment_id),
    CONSTRAINT chk_like_target CHECK (
        (post_id IS NOT NULL AND comment_id IS NULL) OR
        (post_id IS NULL AND comment_id IS NOT NULL)
    )
);

-- ---------------------------------------------------------------------
-- AMIZADES (conexões entre usuários)
-- ---------------------------------------------------------------------
CREATE TABLE friends (
    user_id    INT NOT NULL,
    friend_id  INT NOT NULL,
    status     ENUM('pending', 'accepted', 'blocked') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id),
    CONSTRAINT fk_friends_user   FOREIGN KEY (user_id)   REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_friends_friend FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_friends_self  CHECK (user_id <> friend_id)
);

-- ---------------------------------------------------------------------
-- 5. SEGUIDORES - Requisito 5
-- ---------------------------------------------------------------------
CREATE TABLE follows (
    follower_id  INT NOT NULL,   -- quem segue
    following_id INT NOT NULL,   -- quem é seguido
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, following_id),
    CONSTRAINT fk_follows_follower  FOREIGN KEY (follower_id)  REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_follows_following FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_follows_self CHECK (follower_id <> following_id)
);

-- ---------------------------------------------------------------------
-- 4. MENSAGENS PRIVADAS - Requisito 4
-- ---------------------------------------------------------------------
CREATE TABLE messages (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    sender_id   INT  NOT NULL,
    receiver_id INT  NOT NULL,
    content     TEXT NOT NULL,
    is_read     BOOLEAN DEFAULT FALSE,
    sent_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_messages_sender   FOREIGN KEY (sender_id)   REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_messages_receiver FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_messages_self CHECK (sender_id <> receiver_id)
);

-- ---------------------------------------------------------------------
-- 6. HABILIDADES DE PROGRAMAÇÃO - Requisito 6
-- ---------------------------------------------------------------------
CREATE TABLE skills (
    id       INT AUTO_INCREMENT PRIMARY KEY,
    name     VARCHAR(50) NOT NULL UNIQUE,    -- ex: 'Python', 'SQL', 'Docker'
    category VARCHAR(50)                     -- ex: 'Linguagem', 'Banco de Dados', 'DevOps'
);

CREATE TABLE user_skills (
    user_id     INT NOT NULL,
    skill_id    INT NOT NULL,
    level       ENUM('beginner', 'intermediate', 'advanced', 'expert') DEFAULT 'beginner',
    years_used  INT DEFAULT 0,
    PRIMARY KEY (user_id, skill_id),
    CONSTRAINT fk_us_user  FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE,
    CONSTRAINT fk_us_skill FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- 9. DESAFIOS DE PROGRAMAÇÃO - Requisito 9
-- ---------------------------------------------------------------------
CREATE TABLE challenges (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    difficulty  ENUM('easy', 'medium', 'hard') NOT NULL,
    points      INT NOT NULL DEFAULT 10,
    created_by  INT,
    start_date  DATETIME,
    end_date    DATETIME,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_challenges_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_challenges_points CHECK (points > 0)
);

CREATE TABLE challenge_participants (
    challenge_id INT NOT NULL,
    user_id      INT NOT NULL,
    joined_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (challenge_id, user_id),
    CONSTRAINT fk_cp_challenge FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE,
    CONSTRAINT fk_cp_user      FOREIGN KEY (user_id)      REFERENCES users(id)      ON DELETE CASCADE
);

CREATE TABLE submissions (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    challenge_id INT  NOT NULL,
    user_id      INT  NOT NULL,
    code         TEXT NOT NULL,
    language     VARCHAR(30) NOT NULL,
    status       ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
    score        INT DEFAULT 0,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- só quem participa do desafio pode enviar solução
    CONSTRAINT fk_sub_participant FOREIGN KEY (challenge_id, user_id)
        REFERENCES challenge_participants(challenge_id, user_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- 10. RANKING - Requisito 10
-- ---------------------------------------------------------------------
CREATE TABLE rankings (
    user_id              INT PRIMARY KEY,
    total_points         INT DEFAULT 0,
    challenges_joined    INT DEFAULT 0,
    challenges_completed INT DEFAULT 0,
    position             INT,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_rankings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- ÍNDICES (consultas mais comuns: feed, comentários, mensagens)
-- ---------------------------------------------------------------------
CREATE INDEX idx_posts_user       ON posts (user_id, created_at);
CREATE INDEX idx_posts_group      ON posts (group_id, created_at);
CREATE INDEX idx_comments_post    ON comments (post_id);
CREATE INDEX idx_messages_conv    ON messages (sender_id, receiver_id, sent_at);
CREATE INDEX idx_follows_followed ON follows (following_id);
CREATE INDEX idx_submissions_user ON submissions (user_id);
CREATE INDEX idx_rankings_points  ON rankings (total_points DESC);

-- ---------------------------------------------------------------------
-- PROCEDURE: recalcula o ranking a partir das submissões aceitas
-- Pontuação = soma dos pontos dos desafios distintos resolvidos
-- ---------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE refresh_rankings()
BEGIN
    DELETE FROM rankings;

    INSERT INTO rankings (user_id, total_points, challenges_joined, challenges_completed)
    SELECT u.id,
           COALESCE(SUM(done.points), 0),
           (SELECT COUNT(*) FROM challenge_participants cp WHERE cp.user_id = u.id),
           COUNT(done.challenge_id)
    FROM users u
    LEFT JOIN (
        SELECT DISTINCT s.user_id, s.challenge_id, c.points
        FROM submissions s
        JOIN challenges c ON c.id = s.challenge_id
        WHERE s.status = 'accepted'
    ) done ON done.user_id = u.id
    GROUP BY u.id;

    UPDATE rankings r
    JOIN (
        SELECT user_id, RANK() OVER (ORDER BY total_points DESC) AS pos
        FROM rankings
    ) t ON t.user_id = r.user_id
    SET r.position = t.pos;
END //
DELIMITER ;

-- =====================================================================
--  DADOS DE EXEMPLO
-- =====================================================================
INSERT INTO users (name, username, email, password_hash, city, country, job_title, company, experience_years, github_url) VALUES
('Ana Souza',     'anasouza',  'ana@email.com',    'hash_123', 'Recife',    'Brasil', 'Desenvolvedora Backend',  'TechCorp', 4, 'https://github.com/anasouza'),
('Bruno Lima',    'brunolima', 'bruno@email.com',  'hash_456', 'São Paulo', 'Brasil', 'Desenvolvedor Frontend',  'WebDev',   2, 'https://github.com/brunolima'),
('Carla Mendes',  'carlam',    'carla@email.com',  'hash_789', 'Salvador',  'Brasil', 'Engenheira de Dados',     'DataHub',  6, 'https://github.com/carlam'),
('Diego Rocha',   'diegor',    'diego@email.com',  'hash_000', 'Fortaleza', 'Brasil', 'Estudante',               NULL,       0, 'https://github.com/diegor');

INSERT INTO skills (name, category) VALUES
('Python', 'Linguagem'), ('JavaScript', 'Linguagem'), ('Java', 'Linguagem'),
('SQL', 'Banco de Dados'), ('React', 'Framework'), ('Docker', 'DevOps');

INSERT INTO user_skills (user_id, skill_id, level, years_used) VALUES
(1, 1, 'advanced', 4), (1, 4, 'advanced', 4), (2, 2, 'intermediate', 2),
(2, 5, 'intermediate', 2), (3, 1, 'expert', 6), (3, 4, 'expert', 6), (4, 3, 'beginner', 1);

INSERT INTO tech_groups (name, description, topic, created_by) VALUES
('Pythonistas BR', 'Comunidade de Python',          'Python',     1),
('Frontend Masters', 'Tudo sobre React e JS',        'JavaScript', 2);

INSERT INTO group_members (group_id, user_id, role) VALUES
(1, 1, 'admin'), (1, 3, 'member'), (1, 4, 'member'), (2, 2, 'admin'), (2, 4, 'member');

INSERT INTO posts (user_id, group_id, content, link_url) VALUES
(1, NULL, 'Acabei de publicar um artigo sobre índices no MySQL!', 'https://blog.exemplo.com/indices-mysql'),
(2, NULL, 'Alguém recomenda uma lib de testes para React?',        NULL),
(3, 1,    'Dica: use list comprehensions com moderação.',          NULL),
(4, 2,    'Meu primeiro projeto em React!',                        'https://github.com/diegor/meu-app');

INSERT INTO comments (post_id, user_id, content) VALUES
(1, 2, 'Muito bom, Ana!'), (2, 1, 'Testing Library + Vitest.'), (4, 2, 'Parabéns, Diego!');

INSERT INTO likes (user_id, post_id, comment_id) VALUES
(2, 1, NULL), (3, 1, NULL), (4, 1, NULL), (1, 4, NULL), (2, NULL, 2);

INSERT INTO friends (user_id, friend_id, status) VALUES
(1, 2, 'accepted'), (1, 3, 'accepted'), (2, 4, 'pending');

INSERT INTO follows (follower_id, following_id) VALUES
(2, 1), (3, 1), (4, 1), (4, 2), (1, 3);

INSERT INTO messages (sender_id, receiver_id, content) VALUES
(1, 2, 'Oi Bruno, vamos fazer o desafio juntos?'),
(2, 1, 'Bora!');

INSERT INTO challenges (title, description, difficulty, points, created_by) VALUES
('FizzBuzz',          'Imprima de 1 a 100 com as regras do FizzBuzz.', 'easy',   10, 1),
('Palíndromo',        'Verifique se uma string é palíndromo.',          'easy',   10, 1),
('Caminho mais curto','Implemente o algoritmo de Dijkstra.',            'hard',   50, 3);

INSERT INTO challenge_participants (challenge_id, user_id) VALUES
(1, 1), (1, 2), (1, 4), (2, 2), (3, 3), (3, 1);

INSERT INTO submissions (challenge_id, user_id, code, language, status, score) VALUES
(1, 1, 'for i in range(1,101): ...', 'Python',     'accepted', 10),
(1, 2, 'for (let i=1;i<=100;i++)...', 'JavaScript', 'accepted', 10),
(1, 4, 'public class FizzBuzz {...}', 'Java',       'rejected', 0),
(2, 2, 'const isPal = s => ...',      'JavaScript', 'accepted', 10),
(3, 3, 'import heapq ...',            'Python',     'accepted', 50);

CALL refresh_rankings();

-- =====================================================================
--  CONSULTAS DE EXEMPLO
-- =====================================================================
-- Ranking geral
-- SELECT r.position, u.username, r.total_points, r.challenges_completed
-- FROM rankings r JOIN users u ON u.id = r.user_id ORDER BY r.position;

-- Feed: posts de quem o usuário 4 segue
-- SELECT p.* FROM posts p
-- JOIN follows f ON f.following_id = p.user_id
-- WHERE f.follower_id = 4 ORDER BY p.created_at DESC;
