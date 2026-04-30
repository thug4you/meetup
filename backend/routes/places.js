const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Категории заведений
const VENUE_CATEGORIES = [
  'Кафе',
  'Бар',
  'Ресторан',
  'Кофейня',
  'Фастфуд',
  'Спортзал',
  'Парк',
  'Кинотеатр',
  'Музей',
  'Торговый центр',
  'Боулинг',
  'Караоке',
  'Коворкинг',
  'Другое',
];

// Получить список категорий заведений
router.get('/categories', (req, res) => {
  res.json(VENUE_CATEGORIES);
});

// ============== Яндекс API ==============
const YANDEX_SUGGEST_KEY = '93f6c08d-0796-49f7-8606-5367e7ec5254';
const YANDEX_GEOCODER_KEY = '18d1f891-dda9-4404-a254-1dbebc8f26a7';

// Поиск заведений через Yandex Geosuggest
router.get('/yandex-search', async (req, res) => {
  try {
    const { text, lat, lng } = req.query;

    if (!text || text.trim().length === 0) {
      return res.json([]);
    }

    let url = `https://suggest-maps.yandex.ru/v1/suggest?apikey=${YANDEX_SUGGEST_KEY}&text=${encodeURIComponent(text.trim())}&lang=ru_RU&types=biz&results=15`;

    if (lat && lng) {
      url += `&ll=${lng},${lat}&spn=0.5,0.5`;
    }

    const response = await fetch(url);
    if (!response.ok) {
      console.error('Yandex Suggest error:', response.status, await response.text());
      return res.json([]);
    }

    const data = await response.json();

    if (!data.results || !Array.isArray(data.results)) {
      return res.json([]);
    }

    const places = data.results.map(r => ({
      name: r.title?.text || '',
      address: r.subtitle?.text || '',
      tags: r.tags || [],
      distance: r.distance?.value || null,
      distanceText: r.distance?.text || null,
      uri: r.uri || null,
      fullText: r.text || `${r.title?.text}, ${r.subtitle?.text}`,
    }));

    // Сортировка по расстоянию от пользователя
    places.sort((a, b) => {
      const distA = a.distance !== null ? a.distance : Infinity;
      const distB = b.distance !== null ? b.distance : Infinity;
      return distA - distB;
    });

    res.json(places);
  } catch (err) {
    console.error('Yandex search error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// Геокодирование адреса → координаты
router.get('/geocode', async (req, res) => {
  try {
    const { address } = req.query;

    if (!address) {
      return res.json({ latitude: null, longitude: null });
    }

    const url = `https://geocode-maps.yandex.ru/1.x/?apikey=${YANDEX_GEOCODER_KEY}&geocode=${encodeURIComponent(address)}&format=json&results=1`;

    const response = await fetch(url);
    const data = await response.json();

    const geoObject = data?.response?.GeoObjectCollection?.featureMember?.[0]?.GeoObject;

    if (geoObject?.Point?.pos) {
      const [lon, lat] = geoObject.Point.pos.split(' ');
      return res.json({
        latitude: parseFloat(lat),
        longitude: parseFloat(lon),
        address: geoObject.metaDataProperty?.GeocoderMetaData?.text || address,
      });
    }

    res.json({ latitude: null, longitude: null });
  } catch (err) {
    console.error('Geocode error:', err.message);
    res.json({ latitude: null, longitude: null });
  }
});

// Расширенный поиск мест (по бюджету, расстоянию, категории)
router.get('/search', async (req, res) => {
  try {
    const { query, category, min_bill, max_bill, lat, lng, radius } = req.query;

    let sql = 'SELECT * FROM places WHERE 1=1';
    const params = [];
    let paramIdx = 1;

    // Фильтр по тексту (имя/адрес)
    if (query && query.trim()) {
      sql += ` AND (name ILIKE $${paramIdx} OR address ILIKE $${paramIdx})`;
      params.push(`%${query.trim()}%`);
      paramIdx++;
    }

    // Фильтр по категории
    if (category && category.trim()) {
      sql += ` AND category = $${paramIdx}`;
      params.push(category.trim());
      paramIdx++;
    }

    // Фильтр по среднему чеку (бюджету)
    if (min_bill) {
      sql += ` AND average_bill >= $${paramIdx}`;
      params.push(parseFloat(min_bill));
      paramIdx++;
    }
    if (max_bill) {
      sql += ` AND average_bill <= $${paramIdx}`;
      params.push(parseFloat(max_bill));
      paramIdx++;
    }

    // Если переданы координаты и радиус — фильтр по расстоянию
    // Используем формулу Haversine для расчёта расстояния в метрах
    if (lat && lng && radius) {
      const latF = parseFloat(lat);
      const lngF = parseFloat(lng);
      const radiusM = parseFloat(radius); // радиус в метрах

      sql += ` AND latitude IS NOT NULL AND longitude IS NOT NULL
        AND (
          6371000 * acos(
            cos(radians($${paramIdx})) * cos(radians(latitude)) *
            cos(radians(longitude) - radians($${paramIdx + 1})) +
            sin(radians($${paramIdx})) * sin(radians(latitude))
          )
        ) <= $${paramIdx + 2}`;
      params.push(latF, lngF, radiusM);
      paramIdx += 3;
    }

    sql += ' ORDER BY created_at DESC LIMIT 50';

    const result = await pool.query(sql, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить все места
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM places ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить место по ID
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM places WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Место не найдено' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Создать место
router.post('/', async (req, res) => {
  try {
    const { name, address, latitude, longitude, description, image_url, category, average_bill } = req.body;

    if (!name || !address) {
      return res.status(400).json({ 
        error: 'Обязательные поля не заполнены',
        required: ['name', 'address']
      });
    }

    if (latitude && (latitude < -90 || latitude > 90)) {
      return res.status(400).json({ error: 'Широта должна быть между -90 и 90' });
    }
    if (longitude && (longitude < -180 || longitude > 180)) {
      return res.status(400).json({ error: 'Долгота должна быть между -180 и 180' });
    }

    const result = await pool.query(
      `INSERT INTO places (name, address, latitude, longitude, description, image_url, category, average_bill) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [
        name, 
        address, 
        latitude || null, 
        longitude || null, 
        description || null, 
        image_url || null,
        category || null,
        average_bill || null,
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
