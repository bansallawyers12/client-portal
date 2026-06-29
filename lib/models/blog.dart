class Blog {
  final int id;
  final String title;
  final String description;
  final String image;
  final String author;
  final String date;
  final String url;
  final bool featured;

  Blog({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.author,
    required this.date,
    required this.url,
    required this.featured,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      image: json['image'] ?? '',
      author: json['author'] ?? '',
      date: json['date'] ?? '',
      url: json['url'],
      featured: json['featured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'author': author,
      'date': date,
      'url': url,
      'featured': featured,
    };
  }
}
