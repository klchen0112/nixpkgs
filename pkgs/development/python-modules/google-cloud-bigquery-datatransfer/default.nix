{
  lib,
  buildPythonPackage,
  fetchPypi,
  google-api-core,
  libcst,
  mock,
  proto-plus,
  protobuf,
  pytest-asyncio,
  pytestCheckHook,
  pythonOlder,
  pytz,
  setuptools,
}:

buildPythonPackage rec {
  pname = "google-cloud-bigquery-datatransfer";
  version = "3.19.1";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    pname = "google_cloud_bigquery_datatransfer";
    inherit version;
    hash = "sha256-L7em/I7t7htI5zdGwSKDs35b2t/pvIXl1lUSMM6BdRo=";
  };

  build-system = [ setuptools ];

  dependencies = [
    google-api-core
    libcst
    proto-plus
    protobuf
    pytz
  ] ++ google-api-core.optional-dependencies.grpc;

  nativeCheckInputs = [
    mock
    pytest-asyncio
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "google.cloud.bigquery_datatransfer"
    "google.cloud.bigquery_datatransfer_v1"
  ];

  disabledTests = [
    # Tests require project ID
    "test_list_data_sources"
  ];

  meta = with lib; {
    description = "BigQuery Data Transfer API client library";
    homepage = "https://github.com/googleapis/google-cloud-python/tree/main/packages/google-cloud-bigquery-datatransfer";
    changelog = "https://github.com/googleapis/google-cloud-python/blob/google-cloud-bigquery-datatransfer-v${version}/packages/google-cloud-bigquery-datatransfer/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
