enum UploadTransferStage { saving, uploadingPdf, extractingPdfText }

class UploadResult {
  const UploadResult({
    required this.materialId,
    required this.storagePath,
    required this.fileHash,
  });

  final String materialId;
  final String? storagePath;
  final String fileHash;
}
