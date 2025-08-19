import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookHeader(),
            const SizedBox(height: 24),
            _buildBookInfo(),
            if (book.description != null && book.description!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDescription(),
            ],
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBookHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildBookImage(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'by ${book.author}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              _buildRatingRow(),
              const SizedBox(height: 8),
              _buildStatusChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookImage() {
    if (book.imageUrl.startsWith('http') || book.imageUrl.startsWith('/storage/')) {
      return CachedNetworkImage(
        imageUrl: book.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book,
                size: 40,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No Image',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Image.asset(
        book.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book,
                size: 40,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No Image',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        ...List.generate(5, (i) {
          return Icon(
            Icons.star,
            size: 16,
            color: i < book.rating.floor()
                ? Colors.amber
                : Colors.grey[300],
          );
        }),
        const SizedBox(width: 8),
        Text(
          book.rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: book.isApproved ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        book.isApproved ? 'Approved' : 'Pending',
        style: TextStyle(
          color: book.isApproved ? Colors.green[700] : Colors.orange[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBookInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Category', book.category),
            const SizedBox(height: 8),
            _buildInfoRow('Language', book.language),
            if (book.pdfUrl != null || book.epubUrl != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Available Formats',
                [
                  if (book.pdfUrl != null) 'PDF',
                  if (book.epubUrl != null) 'EPUB',
                ].join(', '),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              book.description!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (book.pdfUrl != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement PDF download/view
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF download coming soon!')),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Read PDF'),
            ),
          ),
        if (book.pdfUrl != null && book.epubUrl != null)
          const SizedBox(width: 12),
        if (book.epubUrl != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement EPUB download/view
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('EPUB download coming soon!')),
                );
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('Read EPUB'),
            ),
          ),
      ],
    );
  }
}
