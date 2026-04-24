const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB connected: ${conn.connection.host}`);

    // Drop the old non-sparse email index if it exists so null emails don't conflict
    try {
      await conn.connection.collection('users').dropIndex('email_1');
      console.log('Dropped old email_1 index — will be recreated as sparse');
    } catch (_) {
      // Index doesn't exist or already correct — ignore
    }
  } catch (error) {
    console.error(`MongoDB connection error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
