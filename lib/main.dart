import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:gql_exec/gql_exec.dart";
import "package:gql_http_link/gql_http_link.dart";
import "package:gql_link/gql_link.dart";
import "package:attendance_app/src/github_gql/github_queries.data.gql.dart";
import "package:attendance_app/src/github_gql/github_queries.req.gql.dart";
import "package:attendance_app/src/github_login.dart";

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter attendance app",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyTopComponent(title: "Flutter attendance app"),
    );
  }
}

class MyTopComponent extends StatelessWidget {
  const MyTopComponent({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return GithubLoginWidget(
      builder: (context, httpClient) {
        final link = HttpLink(
          "https://api.github.com/graphql",
          httpClient: httpClient,
        );
        return FutureBuilder<GViewerDetailData_viewer>(
          future: viewerDetail(link),
          builder: (context, snapshot) {
            return Scaffold(
              appBar: AppBar(
                title: Text(title),
              ),
              body: Center(
                child: Text(
                  snapshot.hasData
                      ? "Hello ${snapshot.data!.login}"
                      : "Retrieving viewer login details...",
                ),
              ),
            );
          },
        );
      },
      githubClientId: dotenv.env["GITHUB_CLIENT_ID"] as String,
      githubClientSecret: dotenv.env["GITHUB_CLIENT_SECRET"] as String,
      githubScopes: ["repo", "read:org"],
    );
  }
}

Future<GViewerDetailData_viewer> viewerDetail(Link link) async {
  final req = GViewerDetail((b) => b);
  final result = await link
    .request(Request(
      operation: req.operation,
      variables: req.vars.toJson(),
    ))
    .first;
  final errors = result.errors;

  if (errors != null && errors.isNotEmpty) {
    throw QueryException(errors);
  }

  return GViewerDetailData.fromJson(result.data!)!.viewer;
}

class QueryException implements Exception {
  QueryException(this.errors);
  List<GraphQLError> errors;

  @override
  String toString() {
    return "Query exception: ${errors.map((err) => "$err").join("'")}";
  }
}
