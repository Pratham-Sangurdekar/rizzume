import 'api_client.dart';

class NLPService {
  Future<List<dynamic>> matchJobs(String resumeText) async {
    final result = await ApiClient.post("jobs/match", {"resume_text": resumeText});
    return result["matches"];
  }

  Future<List<dynamic>> matchUsers(String bio) async {
    final result = await ApiClient.post("users/match", {"bio": bio});
    return result["matches"];
  }
}