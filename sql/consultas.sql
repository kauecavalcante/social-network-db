-- =====================================================================
--  Consultas de exemplo - Social Network DB
--  Executar depois de sql/social_network.sql
-- =====================================================================

USE social_network;

-- 1. Perfil completo dos usuários (dados pessoais e profissionais)
SELECT name, username, city, job_title, company, experience_years
FROM users
ORDER BY name;

-- 2. Posts com número de curtidas e comentários
SELECT p.id,
       u.username,
       p.content,
       (SELECT COUNT(*) FROM likes l    WHERE l.post_id = p.id) AS curtidas,
       (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id) AS comentarios
FROM posts p
JOIN users u ON u.id = p.user_id
ORDER BY curtidas DESC;

-- 3. Seguidores de cada usuário
SELECT u.username,
       COUNT(f.follower_id) AS seguidores
FROM users u
LEFT JOIN follows f ON f.following_id = u.id
GROUP BY u.id, u.username
ORDER BY seguidores DESC;

-- 4. Amigos confirmados
SELECT a.username AS usuario, b.username AS amigo
FROM friends fr
JOIN users a ON a.id = fr.user_id
JOIN users b ON b.id = fr.friend_id
WHERE fr.status = 'accepted';

-- 5. Conversa entre dois usuários (1 e 2)
SELECT s.username AS de, r.username AS para, m.content, m.sent_at
FROM messages m
JOIN users s ON s.id = m.sender_id
JOIN users r ON r.id = m.receiver_id
WHERE (m.sender_id = 1 AND m.receiver_id = 2)
   OR (m.sender_id = 2 AND m.receiver_id = 1)
ORDER BY m.sent_at;

-- 6. Habilidades de cada usuário
SELECT u.username, s.name AS habilidade, us.level AS nivel
FROM user_skills us
JOIN users u  ON u.id = us.user_id
JOIN skills s ON s.id = us.skill_id
ORDER BY u.username, s.name;

-- 7. Grupos e quantidade de membros
SELECT g.name AS grupo, g.topic, COUNT(gm.user_id) AS membros
FROM tech_groups g
LEFT JOIN group_members gm ON gm.group_id = g.id
GROUP BY g.id, g.name, g.topic;

-- 8. Desafios com participantes e soluções aceitas
SELECT c.title,
       c.difficulty,
       (SELECT COUNT(*) FROM challenge_participants cp WHERE cp.challenge_id = c.id) AS participantes,
       (SELECT COUNT(*) FROM submissions s WHERE s.challenge_id = c.id AND s.status = 'accepted') AS aceitas
FROM challenges c;

-- 9. Top 3 do ranking
SELECT r.position, u.username, r.total_points
FROM rankings r
JOIN users u ON u.id = r.user_id
ORDER BY r.position
LIMIT 3;
