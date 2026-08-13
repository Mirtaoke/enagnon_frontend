import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../data/providers/api_provider.dart';
import '../data/providers/storage_provider.dart';

class ReportExportService {
  final ApiProvider apiProvider;
  final StorageProvider storageProvider;
  ReportExportService({
    ApiProvider? apiProvider,
    StorageProvider? storageProvider,
  }) : apiProvider = apiProvider ?? ApiProvider(),
       storageProvider = storageProvider ?? StorageProvider();

  Future<ReportExportFile> prepare(
    int shopId,
    String format, {
    int? reportId,
  }) async {
    final token = await storageProvider.getToken();
    final bytes = await apiProvider.getBytes(
      '/shops/$shopId/reports-export?format=$format${reportId == null ? '' : '&report_id=$reportId'}',
      token: token,
    );
    final typedBytes = Uint8List.fromList(bytes);
    final directory = await getTemporaryDirectory();
    final name = reportId == null
        ? 'rapports-point-$shopId'
        : 'rapport-$reportId-point-$shopId';
    final file = File('${directory.path}/$name.$format');
    await file.writeAsBytes(typedBytes, flush: true);
    return ReportExportFile(
      name: name,
      extension: format,
      bytes: typedBytes,
      path: file.path,
    );
  }

  Future<String> download(ReportExportFile export) async =>
      await FileSaver.instance.saveAs(
        name: export.name,
        bytes: export.bytes,
        fileExtension: export.extension,
        mimeType: MimeType.custom,
        customMimeType: switch (export.extension) {
          'pdf' => 'application/pdf',
          'csv' => 'text/csv',
          _ => 'application/vnd.ms-excel',
        },
      ) ??
      'Enregistrement annulé';
}

class ReportExportFile {
  final String name;
  final String extension;
  final Uint8List bytes;
  final String path;

  const ReportExportFile({
    required this.name,
    required this.extension,
    required this.bytes,
    required this.path,
  });
}
