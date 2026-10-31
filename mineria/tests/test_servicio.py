"""Pruebas del servicio de predicción. Correr desde mineria/: venv\\Scripts\\pytest -q"""
from fastapi.testclient import TestClient

from service.app import app

cliente = TestClient(app, raise_server_exceptions=False)

EJEMPLOS = {
    "demanda": {"alcance": "todas", "semanas": 4, "escenario": "con_drop"},
    "recompra": {"frecuencia": 3, "ticket_promedio": 250000, "recencia_dias": 30, "antiguedad_dias": 240,
                 "metodo_pago": "CARD"},
    "segmento": {"frecuencia_anual": 6, "ticket_promedio": 300000, "recencia_dias": 30},
}


def test_health():
    r = cliente.get("/health")
    assert r.status_code == 200 and r.json()["estado"] == "ok"


def test_catalogo_tiene_las_tres_predicciones():
    ids = [p["id"] for p in cliente.get("/predicciones").json()["predicciones"]]
    assert ids == ["demanda", "recompra", "segmento"]


def test_cada_prediccion_y_sus_graficas():
    for id_pred, valores in EJEMPLOS.items():
        r = cliente.post(f"/predecir/{id_pred}", json={"valores": valores})
        assert r.status_code == 200, r.text
        cuerpo = r.json()
        assert cuerpo["prediccion"] == id_pred and cuerpo["resultado"]["texto"]
        g = cliente.get(f"/graficas/{cuerpo['id_prediccion']}")
        assert g.status_code == 200
        datos = g.json()
        assert datos["referencia"]["id_prediccion"] == cuerpo["id_prediccion"]
        assert len(datos["graficas"]) >= 4


def test_demanda_con_drop_supera_sin_drop_cuando_el_drop_esta_en_el_horizonte():
    con = cliente.post("/predecir/demanda", json={"valores": {"alcance": "todas", "semanas": 12, "escenario": "con_drop"}})
    sin = cliente.post("/predecir/demanda", json={"valores": {"alcance": "todas", "semanas": 12, "escenario": "sin_drop"}})
    assert con.json()["resultado"]["valor"] > sin.json()["resultado"]["valor"]


def test_valores_invalidos_devuelven_400():
    r = cliente.post("/predecir/demanda", json={"valores": {"semanas": 99}})
    assert r.status_code == 400 and "semanas" in r.json()["error"]
    r = cliente.post("/predecir/recompra", json={"valores": {**EJEMPLOS["recompra"], "recencia_dias": 500,
                                                             "antiguedad_dias": 100}})
    assert r.status_code == 400


def test_cuerpo_mal_formado_devuelve_400():
    r = cliente.post("/predecir/segmento", content="esto no es json", headers={"Content-Type": "application/json"})
    assert r.status_code == 400


def test_ids_inexistentes_devuelven_404():
    assert cliente.post("/predecir/no_existe", json={"valores": {}}).status_code == 404
    assert cliente.get("/graficas/abc123").status_code == 404
