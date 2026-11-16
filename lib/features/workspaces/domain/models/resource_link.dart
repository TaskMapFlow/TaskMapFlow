import 'package:equatable/equatable.dart';

class ResourceLink extends Equatable {
  const ResourceLink({
    required this.id,
    required this.title,
    required this.url,
  });

  final String id;
  final String title;
  final String url;

  static bool isValidUrl(String url) {
    final trimmed = url.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return false;
    }
    final uri = Uri.tryParse(trimmed);
    return uri != null && uri.hasAuthority && uri.host.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
    };
  }

  factory ResourceLink.fromMap(Map<String, dynamic> map) {
    return ResourceLink(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      url: map['url'] as String? ?? '',
    );
  }

  ResourceLink copyWith({
    String? id,
    String? title,
    String? url,
  }) {
    return ResourceLink(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
    );
  }

  @override
  List<Object?> get props => [id, title, url];
}
