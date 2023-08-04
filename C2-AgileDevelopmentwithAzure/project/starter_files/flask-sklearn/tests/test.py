from app import app


def test_home():
    response = app.test_client().get('/')
    assert response.status_code == 200
    assert response.data == b'<h3>Sklearn Prediction Home</h3>'


def test_predict():
    response = app.test_client().post(
        '/predict',
        json={
            'CHAS': {'0': 0},
            'RM': {'0': 6.575},
            'TAX': {'0': 296.0},
            'PTRATIO': {'0': 15.3},
            'B': {'0': 396.9},
            'LSTAT': {'0': 4.98}
            })
    assert response.status_code == 200
    assert response.data == b'{"prediction":[2.431574790057212]}\n'
