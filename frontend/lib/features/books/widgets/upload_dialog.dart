import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/books_provider.dart';
import '../../../core/constants/book_constants.dart';

class UploadDialog extends StatefulWidget {
  const UploadDialog({Key? key}) : super(key: key);

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _languageController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  XFile? _coverImage;
  PlatformFile? _bookFile;
  String? _pickedBookType;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _languageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Book'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _languageController,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildCoverImageSection(),
            const SizedBox(height: 12),
            _buildBookFileSection(),
            if (_isUploading) ...[
              const SizedBox(height: 16),
              _buildUploadProgress(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _handleUpload,
          child: _isUploading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Upload'),
        ),
      ],
    );
  }

  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cover Image *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickCoverImage,
              icon: const Icon(Icons.image),
              label: Text(_coverImage != null ? 'Change Cover' : 'Pick Cover'),
            ),
            if (_coverImage != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(_coverImage!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBookFileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Book File *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickBookFile,
            icon: const Icon(Icons.upload_file),
            label: Text(
              _bookFile != null
                  ? (_bookFile!.name.length > 30 
                      ? '${_bookFile!.name.substring(0, 30)}...'
                      : _bookFile!.name)
                  : 'Pick PDF or EPUB',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (_bookFile != null) ...[
          const SizedBox(height: 4),
          Text(
            'Size: ${_formatFileSize(_bookFile!.size)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      children: [
        LinearProgressIndicator(value: _uploadProgress),
        const SizedBox(height: 8),
        Text(
          'Uploading... ${(_uploadProgress * 100).toInt()}%',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _pickCoverImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      if (file.lengthSync() > BookConstants.maxCoverSize) {
        _showErrorSnackBar('Cover image must be less than 5MB');
        return;
      }
      setState(() {
        _coverImage = picked;
      });
    }
  }

  Future<void> _pickBookFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: BookConstants.supportedBookFormats,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      
      if (file.size > BookConstants.maxFileSize) {
        _showErrorSnackBar('Book file must be less than 50MB');
        return;
      }
      
      final ext = file.extension?.toLowerCase();
      setState(() {
        _bookFile = file;
        _pickedBookType = BookConstants.supportedBookFormats.contains(ext) ? ext : null;
      });
    }
  }

  Future<void> _handleUpload() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Title is required');
      return;
    }
    
    if (_authorController.text.trim().isEmpty) {
      _showErrorSnackBar('Author is required');
      return;
    }
    
    if (_coverImage == null) {
      _showErrorSnackBar('Cover image is required');
      return;
    }
    
    if (_bookFile == null || _pickedBookType == null) {
      _showErrorSnackBar('Please select a valid PDF or EPUB file');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final booksProvider = Provider.of<BooksProvider>(context, listen: false);
      
      final success = await booksProvider.uploadBook(
        title: _titleController.text,
        author: _authorController.text,
        category: _categoryController.text.isNotEmpty 
            ? _categoryController.text 
            : 'Uncategorized',
        language: _languageController.text.isNotEmpty 
            ? _languageController.text 
            : 'Unknown',
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
        coverImage: File(_coverImage!.path),
        bookFile: File(_bookFile!.path!),
        bookType: _pickedBookType,
        context: context,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar('Upload failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }

    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
