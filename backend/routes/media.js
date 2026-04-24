const express = require('express');
const multer  = require('multer');
const Media   = require('../models/Media');
const { protect } = require('../middleware/auth');

const router = express.Router();
router.use(protect);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 15 * 1024 * 1024 }, // 15 MB max
  fileFilter(req, file, cb) {
    if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image and video files are allowed'));
    }
  },
});

// POST /api/media — upload a file, returns { mediaId }
router.post('/', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file provided' });

    const media = await Media.create({
      uploaderId: req.user.userId,
      mimeType:   req.file.mimetype,
      size:       req.file.size,
      data:       req.file.buffer,
    });

    res.status(201).json({ mediaId: media._id.toString() });
  } catch (error) {
    res.status(500).json({ message: 'Upload failed', error: error.message });
  }
});

// GET /api/media/:id — stream the file back
router.get('/:id', async (req, res) => {
  try {
    const media = await Media.findById(req.params.id);
    if (!media) return res.status(404).json({ message: 'Media not found' });

    res.set('Content-Type', media.mimeType);
    res.set('Content-Length', media.size);
    res.set('Cache-Control', 'private, max-age=86400');
    res.send(media.data);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch media', error: error.message });
  }
});

module.exports = router;
