import '../entities/public_page_content.dart';

abstract class PublicPageRepository {
  Stream<PublicPageContent> watchContent(String weddingId);
  Future<void> updateContent(String weddingId, PublicPageContent content);
}
