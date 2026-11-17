import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class LocalProxyEngine {
  HttpServer? _server;
  final Function(String clientIp, int bytesSent) onDataTransferred;
  final bool Function(String clientIp) isClientAllowed;

  LocalProxyEngine({
    required this.onDataTransferred,
    required this.isClientAllowed,
  });

  Future<void> startServer({int port = 8080}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      if (kDebugMode) {
        print("Hospo Proxy running on port ${_server?.port}");
      }

      _server?.listen((HttpRequest request) async {
        String clientIp = request.connectionInfo?.remoteAddress.address ?? "";

        // ডাটা লিমিট ওভার হলে ব্লক করা
        if (!isClientAllowed(clientIp)) {
          request.response.statusCode = HttpStatus.forbidden;
          request.response.write("Hospo Data Limit Exceeded!");
          await request.response.close();
          return;
        }

        try {
          final client = HttpClient();
          final proxyRequest = await client.openUrl(request.method, request.uri);
          
          request.headers.forEach((name, values) {
            proxyRequest.headers.add(name, values);
          });

          int requestBytes = 0;
          await request.listen((data) {
            requestBytes += data.length;
            proxyRequest.add(data);
          }).asFuture();

          final proxyResponse = await proxyRequest.close();
          
          proxyResponse.headers.forEach((name, values) {
            request.response.headers.add(name, values);
          });

          int responseBytes = 0;
          await proxyResponse.listen((data) {
            responseBytes += data.length;
            request.response.add(data);
          }).asFuture();

          await request.response.close();

          // ডাটা ব্যবহারের হিসাব আপডেট 콜백
          int totalTransferred = requestBytes + responseBytes;
          onDataTransferred(clientIp, totalTransferred);
        } catch (e) {
          request.response.statusCode = HttpStatus.badGateway;
          await request.response.close();
        }
      });
    } catch (e) {
      if (kDebugMode) print("Proxy Error: $e");
    }
  }

  void stopServer() {
    _server?.close(force: true);
  }
}
