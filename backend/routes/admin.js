const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authMiddleware } = require('../middleware/auth');

// Middleware для проверки роли админа
const adminMiddleware = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const result = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    if (result.rows[0].role !== 'admin') {
      return res.status(403).json({ error: 'Доступ запрещён. Требуются права администратора' });
    }
    
    next();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ==================== ПОЛЬЗОВАТЕЛИ ====================

// Получить всех пользователей
router.get('/users', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 20, search = '' } = req.query;
    const offset = (page - 1) * limit;
    
    let query = `
      SELECT id, email, name, phone, avatar_url, bio, role, created_at, updated_at 
      FROM users 
    `;
    let countQuery = 'SELECT COUNT(*) FROM users';
    const params = [];
    
    if (search) {
      query += ` WHERE name ILIKE $1 OR email ILIKE $1`;
      countQuery += ` WHERE name ILIKE $1 OR email ILIKE $1`;
      params.push(`%${search}%`);
    }
    
    query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);
    
    const [usersResult, countResult] = await Promise.all([
      pool.query(query, params),
      pool.query(countQuery, search ? [`%${search}%`] : [])
    ]);
    
    res.json({
      users: usersResult.rows,
      total: parseInt(countResult.rows[0].count),
      page: parseInt(page),
      limit: parseInt(limit)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить пользователя по ID
router.get('/users/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'SELECT id, email, name, phone, avatar_url, bio, role, created_at, updated_at FROM users WHERE id = $1',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Обновить роль пользователя (назначить админом)
router.put('/users/:id/role', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.body;
    
    if (!['user', 'admin'].includes(role)) {
      return res.status(400).json({ error: 'Недопустимая роль. Допустимые значения: user, admin' });
    }
    
    const result = await pool.query(
      'UPDATE users SET role = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id, email, name, role',
      [role, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    res.json({
      message: `Роль пользователя успешно изменена на ${role}`,
      user: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Удалить пользователя
router.delete('/users/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const adminId = req.user.id;
    
    // Нельзя удалить самого себя
    if (parseInt(id) === adminId) {
      return res.status(400).json({ error: 'Нельзя удалить самого себя' });
    }
    
    const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING id, email, name', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }
    
    res.json({
      message: 'Пользователь успешно удалён',
      user: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== ВСТРЕЧИ ====================

// Получить все встречи
router.get('/meetings', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 20, status = '', search = '' } = req.query;
    const offset = (page - 1) * limit;
    
    let query = `
      SELECT m.*, u.name as organizer_name, u.email as organizer_email,
             (SELECT COUNT(*) FROM meeting_participants WHERE meeting_id = m.id) as participants_count
      FROM meetings m
      LEFT JOIN users u ON m.organizer_id = u.id
    `;
    let countQuery = 'SELECT COUNT(*) FROM meetings m';
    const params = [];
    const conditions = [];
    
    if (status) {
      conditions.push(`m.status = $${params.length + 1}`);
      params.push(status);
    }
    
    if (search) {
      conditions.push(`(m.title ILIKE $${params.length + 1} OR m.description ILIKE $${params.length + 1})`);
      params.push(`%${search}%`);
    }
    
    if (conditions.length > 0) {
      const whereClause = ' WHERE ' + conditions.join(' AND ');
      query += whereClause;
      countQuery += whereClause;
    }
    
    query += ` ORDER BY m.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);
    
    const countParams = params.slice(0, params.length - 2);
    
    const [meetingsResult, countResult] = await Promise.all([
      pool.query(query, params),
      pool.query(countQuery, countParams)
    ]);
    
    res.json({
      meetings: meetingsResult.rows,
      total: parseInt(countResult.rows[0].count),
      page: parseInt(page),
      limit: parseInt(limit)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить встречу по ID
router.get('/meetings/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT m.*, u.name as organizer_name, u.email as organizer_email,
             (SELECT COUNT(*) FROM meeting_participants WHERE meeting_id = m.id) as participants_count
      FROM meetings m
      LEFT JOIN users u ON m.organizer_id = u.id
      WHERE m.id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Встреча не найдена' });
    }
    
    // Получаем участников
    const participants = await pool.query(`
      SELECT u.id, u.name, u.email, u.avatar_url, mp.status, mp.joined_at
      FROM meeting_participants mp
      JOIN users u ON mp.user_id = u.id
      WHERE mp.meeting_id = $1
    `, [id]);
    
    res.json({
      ...result.rows[0],
      participants: participants.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Обновить статус встречи
router.put('/meetings/:id/status', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    const allowedStatuses = ['active', 'cancelled', 'completed', 'pending'];
    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({ 
        error: `Недопустимый статус. Допустимые значения: ${allowedStatuses.join(', ')}` 
      });
    }
    
    const result = await pool.query(
      'UPDATE meetings SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Встреча не найдена' });
    }
    
    res.json({
      message: `Статус встречи успешно изменён на ${status}`,
      meeting: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Удалить встречу
router.delete('/meetings/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query('DELETE FROM meetings WHERE id = $1 RETURNING id, title', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Встреча не найдена' });
    }
    
    res.json({
      message: 'Встреча успешно удалена',
      meeting: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==================== СТАТИСТИКА ====================

// Получить статистику для дашборда
router.get('/stats', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const [
      usersCount,
      adminsCount,
      meetingsCount,
      activeMeetingsCount,
      messagesCount,
      reportsCount
    ] = await Promise.all([
      pool.query('SELECT COUNT(*) FROM users'),
      pool.query("SELECT COUNT(*) FROM users WHERE role = 'admin'"),
      pool.query('SELECT COUNT(*) FROM meetings'),
      pool.query("SELECT COUNT(*) FROM meetings WHERE status = 'active'"),
      pool.query('SELECT COUNT(*) FROM messages'),
      pool.query("SELECT COUNT(*) FROM reports WHERE status = 'pending'")
    ]);
    
    res.json({
      users: {
        total: parseInt(usersCount.rows[0].count),
        admins: parseInt(adminsCount.rows[0].count)
      },
      meetings: {
        total: parseInt(meetingsCount.rows[0].count),
        active: parseInt(activeMeetingsCount.rows[0].count)
      },
      messages: parseInt(messagesCount.rows[0].count),
      pendingReports: parseInt(reportsCount.rows[0].count)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
