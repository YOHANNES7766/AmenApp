import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../../../core/constants/book_constants.dart';
import '../../../core/constants/api_constants.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookCard({
    Key? key,
    required this.book,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildBookImage(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            book.title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            book.author,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        Icons.star,
                        size: 6,
                        color: i < book.rating.floor()
                            ? Colors.amber
                            : Colors.grey[300],
                      );
                    }),
                    const SizedBox(width: 2),
                    Text(
                      book.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: book.isApproved ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    book.category,
                    style: TextStyle(
                      color: book.isApproved ? Colors.green[700] : Colors.orange[700],
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookImage() {
    String imageUrl = _getFullImageUrl(book.imageUrl);
    
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
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
                size: 24,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 4),
              Text(
                'No Image',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
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
                size: 24,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 4),
              Text(
                'No Image',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _getFullImageUrl(String imageUrl) {
    // If already a full URL, return as is
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    
    // If it's a storage path, prepend the base URL
    if (imageUrl.startsWith('/storage/')) {
      return '${ApiConstants.baseUrl}$imageUrl';
    }
    
    // If it's an asset path, return as is
    if (imageUrl.startsWith('assets/')) {
      return imageUrl;
    }
    
    // Default fallback
    return imageUrl;
  }
}
