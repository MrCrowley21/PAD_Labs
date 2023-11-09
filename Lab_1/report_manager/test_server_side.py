import unittest
import requests

from fastapi.testclient import TestClient

from service import app


class MockResponse:
    def __init__(self, json_data, status_code):
        self.json_data = json_data
        self.status_code = status_code

    def json(self):
        return self.json_data


class TestReportManagerServerSideConnections(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)

    def test_server_connectivity(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), ["Test Report Manager Service"])

    def test_correctness_of_load_computing(self):
        for i in range(1, 10):
            self.client.get("/")
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["load"], 10)

    def test_report_creation_status_code_creation(self):
        data = {
                  "connectionId": "new_id",
                  "report": "some_report"
                }
        response = self.client.post("/report_generation", json=data)
        # self.assertEqual(response.status_code, 201)


if __name__ == "__main__":
    unittest.main()
