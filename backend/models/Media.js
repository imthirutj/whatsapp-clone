const mongoose = require('mongoose');

const mediaSchema = new mongoose.Schema({
  uploaderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  mimeType:   { type: String, required: true },
  size:       { type: Number, required: true },
  data:       { type: Buffer, required: true },
}, { timestamps: true });

module.exports = mongoose.model('Media', mediaSchema);
