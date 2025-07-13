import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbHelper {
  static final LocalDbHelper _instance = LocalDbHelper._internal();
  factory LocalDbHelper() => _instance;
  LocalDbHelper._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'books.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE downloaded_books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id TEXT,
            title TEXT,
            author TEXT,
            file_path TEXT,
            format TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertBook(Map<String, dynamic> book) async {
    final dbClient = await db;
    await dbClient.insert('downloaded_books', book,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getDownloadedBooks() async {
    final dbClient = await db;
    return await dbClient.query('downloaded_books');
  }

  Future<void> deleteBook(String bookId) async {
    final dbClient = await db;
    await dbClient
        .delete('downloaded_books', where: 'book_id = ?', whereArgs: [bookId]);
  }

  Future<void> clearAll() async {
    final dbClient = await db;
    await dbClient.delete('downloaded_books');
  }
}
