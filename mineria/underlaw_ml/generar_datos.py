"""Generador de datos SINTÉTICOS para la minería de UnderLaw.

Por qué sintéticos: la tienda real tiene muy pocos pedidos todavía, lo que no
alcanza para entrenar ni evaluar modelos. Este script simula 24 meses de
operación con la MISMA estructura de tablas de la base real (ver
sql/01_esquema.sql) y comportamientos plausibles para una marca de ropa en
Colombia. Todo sale de una semilla fija: si se corre de nuevo, los datos son
idénticos. Los datos NO representan clientes ni ventas reales.

Uso (desde la carpeta mineria/):
    venv\\Scripts\\python -m underlaw_ml.generar_datos

Salida:
    data/export/*.csv            una tabla por archivo
    data/export/evidencia.xlsx   las mismas tablas, una hoja por tabla
    sql/02_datos.sql             INSERTs para cargar en MySQL Workbench
"""
import json
import unicodedata
from datetime import date, datetime, timedelta

import numpy as np
import pandas as pd

from .config import DIR_EXPORT, DIR_SQL, FECHA_CORTE, FECHA_INICIO, SEMILLA

rng = np.random.default_rng(SEMILLA)

PEDIDOS_OBJETIVO = 4100  # ~4.000 aprobados + algunos rechazados/anulados

# ─────────────────────────── catálogo y lanzamientos ───────────────────────────
SECCIONES = [(1, "Camisetas", 1), (2, "Hoodies", 2), (3, "Pantalones", 3), (4, "Accesorios", 4)]
RANGO_PRECIO = {1: (110_000, 135_000), 2: (190_000, 235_000), 3: (160_000, 190_000), 4: (45_000, 85_000)}
DETALLE = {1: "Algodón 240 gsm · Oversized unisex", 2: "Felpa 380 gsm · Capucha doble",
           3: "Drill pesado · Bolsillos cargo", 4: "Accesorio de edición limitada"}

# (nombre del lanzamiento, fecha del drop, [(sección, nombre del producto)])
DROPS = [
    ("First Law", date(2024, 10, 4), [(1, "Oversized Buddha Tee"), (1, "Oversized First"), (4, "Gorra First Law")]),
    ("Second Chapter", date(2025, 1, 24), [(1, "Metamorph Tee"), (1, "Stallion Tee"), (2, "Hoodie Second Chapter")]),
    ("Third Law", date(2025, 4, 25), [(1, "Void Tee"), (1, "Noir Tee"), (3, "Cargo Third Law"), (4, "Bandana Void")]),
    ("Marea", date(2025, 7, 11), [(1, "Camiseta Marea"), (2, "Hoodie Marea"), (3, "Jogger Marea")]),
    ("Origen", date(2025, 9, 19), [(1, "Camiseta Sello"), (1, "Camiseta Ley Propia"), (1, "Camiseta Cartagena 26"), (4, "Gorra Origen")]),
    ("Noche Negra", date(2025, 11, 21), [(1, "Oversized Noche"), (2, "Hoodie Noche Negra"), (3, "Cargo Carbón"), (4, "Tote Bag Noir")]),
    ("Racing", date(2026, 3, 13), [(1, "Racing Tee"), (2, "Hoodie Racing"), (4, "Gorra Racing")]),
    ("Graphic", date(2026, 6, 5), [(1, "Graphic Tee"), (1, "Bhuda Tee"), (2, "Hoodie Graphic"), (3, "Jogger Graphic")]),
    ("Underlaw Studio", date(2026, 8, 28), [(1, "Studio Butterfly Tee"), (2, "Hoodie Studio"), (4, "Bandana Studio")]),
]
# Drop futuro (programado): sirve para el escenario "con lanzamiento" de la predicción.
DROP_FUTURO = ("Drop Diciembre", datetime(2026, 11, 27, 20, 0), (2, "Hoodie Diciembre"))

# ─────────────────────────────── clientes ───────────────────────────────
NOMBRES = ["Valentina", "Santiago", "Camila", "Sebastián", "Isabella", "Mateo", "Mariana", "Samuel",
           "Daniela", "Nicolás", "Sofía", "Alejandro", "Gabriela", "Andrés", "Laura", "Juan", "Paula",
           "David", "Natalia", "Felipe", "Juliana", "Diego", "Manuela", "Tomás", "Sara", "Miguel",
           "Antonia", "Emmanuel", "Luciana", "Carlos", "Salomé", "Esteban", "María José", "Kevin",
           "Ana", "Jerónimo", "Valeria", "Simón", "Catalina", "Julián"]
APELLIDOS = ["Gómez", "Rodríguez", "Martínez", "Hernández", "López", "García", "Pérez", "Díaz",
             "Ramírez", "Torres", "Romero", "Castro", "Vargas", "Rojas", "Moreno", "Ortiz", "Jiménez",
             "Ruiz", "Mendoza", "Herrera", "Medina", "Aguilar", "Cárdenas", "Ríos", "Simancas", "Berrío",
             "Pacheco", "Padilla", "Marrugo", "Julio", "Caraballo", "Barrios", "Arrieta", "Salgado",
             "Villadiego", "Puello", "Cassiani", "Montes", "Navarro", "Ospina"]
DOMINIOS = ["gmail.com", "gmail.com", "gmail.com", "hotmail.com", "outlook.com", "yahoo.com"]
CIUDADES = [  # (ciudad, departamento, peso)
    ("Cartagena", "Bolívar", 0.34), ("Bogotá", "Bogotá D.C.", 0.20), ("Barranquilla", "Atlántico", 0.14),
    ("Medellín", "Antioquia", 0.12), ("Cali", "Valle del Cauca", 0.07), ("Santa Marta", "Magdalena", 0.05),
    ("Montería", "Córdoba", 0.04), ("Sincelejo", "Sucre", 0.04),
]
METODOS_PAGO = (["CARD", "PSE", "NEQUI"], [0.45, 0.33, 0.22])
TALLAS = (["S", "M", "L", "XL"], [0.15, 0.36, 0.33, 0.16])

# Comportamiento por segmento (oculto: los modelos NO ven esta etiqueta).
SEGMENTOS = {
    #            participación, compras/año, días hasta abandonar (media),
    #            ítems por pedido (valores, probabilidades), preferencia por sección 1..4
    "ocasional": dict(peso=0.60, tasa=2.0, abandono=220, items=([1, 2, 3], [0.35, 0.40, 0.25]),
                      seccion=[0.55, 0.15, 0.10, 0.20]),
    "frecuente": dict(peso=0.28, tasa=9.0, abandono=520, items=([1, 2, 3, 4], [0.20, 0.35, 0.30, 0.15]),
                      seccion=[0.45, 0.20, 0.15, 0.20]),
    "premium":   dict(peso=0.12, tasa=6.5, abandono=650, items=([2, 3, 4, 5], [0.15, 0.35, 0.30, 0.20]),
                      seccion=[0.30, 0.35, 0.20, 0.15]),
}
N_CLIENTES = 900


def _ascii(texto: str) -> str:
    return unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode().lower().replace(" ", "")


def _nesimo_dia(anio: int, mes: int, dia_semana: int, n: int) -> date:
    """n-ésimo día de la semana (lunes=0) de un mes."""
    d = date(anio, mes, 1)
    while d.weekday() != dia_semana:
        d += timedelta(days=1)
    return d + timedelta(weeks=n - 1)


def multiplicador_diario(dias: list[date]) -> np.ndarray:
    """Tendencia × estacionalidad × día de la semana × efecto de los drops."""
    n = len(dias)
    t = np.linspace(0, 1, n)
    tendencia = 0.75 + 0.60 * t
    mes = {1: 0.75, 2: 0.80, 3: 0.95, 4: 1.00, 5: 1.10, 6: 1.15, 7: 1.05, 8: 0.95,
           9: 1.05, 10: 1.00, 11: 1.25, 12: 1.60}
    semana = [0.85, 0.85, 0.90, 1.00, 1.20, 1.25, 1.00]
    m = np.array([tendencia[i] * mes[d.month] * semana[d.weekday()] for i, d in enumerate(dias)])

    fechas_especiales = []
    for anio in range(dias[0].year, dias[-1].year + 1):
        black_friday = _nesimo_dia(anio, 11, 3, 4) + timedelta(days=1)       # día después del 4.º jueves
        fechas_especiales += [(black_friday, -2, 3, 1.8)]
        fechas_especiales += [(_nesimo_dia(anio, 5, 6, 2), -7, 0, 1.4)]      # Día de la Madre (2.º domingo de mayo)
        fechas_especiales += [(_nesimo_dia(anio, 6, 6, 3), -5, 0, 1.25)]     # Día del Padre (3.er domingo de junio)
        fechas_especiales += [(_nesimo_dia(anio, 9, 5, 3), -5, 0, 1.3)]      # Amor y Amistad (3.er sábado de sept.)
        fechas_especiales += [(date(anio, 12, 24), -9, 0, 1.3)]              # Navidad
    for centro, antes, despues, factor in fechas_especiales:
        for i, d in enumerate(dias):
            if antes <= (d - centro).days <= despues:
                m[i] *= factor

    efecto_drop = np.ones(n)
    for _, fecha_drop, _ in DROPS:
        for i, d in enumerate(dias):
            k = (d - fecha_drop).days
            if 0 <= k <= 35:
                efecto_drop[i] += 1.6 * np.exp(-k / 6)
    return m * efecto_drop


def construir_catalogo():
    productos, lanzamientos = [], []
    pid = 0
    for nombre_drop, fecha_drop, items in DROPS:
        primero = None
        for seccion, nombre in items:
            pid += 1
            primero = primero or pid
            lo, hi = RANGO_PRECIO[seccion]
            precio = float(round(rng.uniform(lo, hi) / 5000) * 5000)
            tallas = ["Única"] if seccion == 4 else TALLAS[0]
            stock = [{"talla": t, "cantidad": int(rng.integers(0, 40))} for t in tallas]
            productos.append(dict(
                id=pid, nombre_lanzamiento=nombre_drop, nombre_producto=nombre, precio=precio,
                imagen=None, imagen_public_id=None,
                estado="suspendido" if fecha_drop < date(2025, 6, 1) else "activo",
                fecha_creacion=datetime.combine(fecha_drop, datetime.min.time()) + timedelta(hours=20),
                descripcion=f"{nombre} del drop {nombre_drop}. Serie limitada.",
                detalle=DETALLE[seccion], tallas=stock, seccion_id=seccion,
                _fecha_drop=fecha_drop, _popularidad=float(rng.lognormal(0, 0.35)),
            ))
        principal = productos[primero - 1]
        lanzamientos.append(dict(
            nombre_lanzamiento=nombre_drop, nombre_producto=principal["nombre_producto"],
            precio=principal["precio"], imagenes=[],
            # La BD real guarda fecha_lanzamiento en UTC (Colombia = UTC-5): 8:00 p. m. → 01:00 UTC del día siguiente.
            fecha_lanzamiento=datetime.combine(fecha_drop, datetime.min.time()) + timedelta(hours=25),
            activo_en_home=0, estado="lanzado", producto_id=primero,
            created_at=datetime.combine(fecha_drop, datetime.min.time()) - timedelta(days=14),
            descripcion=f"Lanzamiento {nombre_drop}.", detalle=DETALLE[principal["seccion_id"]],
            tallas=principal["tallas"], seccion_id=principal["seccion_id"],
        ))
    nombre_drop, fecha, (seccion, nombre) = DROP_FUTURO
    lanzamientos.append(dict(
        nombre_lanzamiento=nombre_drop, nombre_producto=nombre, precio=215000.0, imagenes=[],
        fecha_lanzamiento=fecha + timedelta(hours=5), activo_en_home=1, estado="programado",
        producto_id=None, created_at=datetime(2026, 9, 25, 10, 0),
        descripcion="Drop de temporada navideña.", detalle=DETALLE[seccion],
        tallas=[{"talla": t, "cantidad": None} for t in TALLAS[0]], seccion_id=seccion,
    ))
    for i, l in enumerate(lanzamientos, start=1):
        l["id"] = i
    return productos, lanzamientos


def construir_clientes(n_dias: int):
    nombres_seg = list(SEGMENTOS)
    seg = rng.choice(nombres_seg, size=N_CLIENTES, p=[SEGMENTOS[s]["peso"] for s in nombres_seg])
    # Más altas a medida que la marca crece (densidad creciente en el tiempo).
    dias_alta = np.arange(n_dias - 20)
    p_alta = 0.5 + dias_alta / len(dias_alta)
    alta = rng.choice(dias_alta, size=N_CLIENTES, p=p_alta / p_alta.sum())
    clientes, usados = [], set()
    ciudades_p = np.array([c[2] for c in CIUDADES])
    for i in range(N_CLIENTES):
        s = SEGMENTOS[seg[i]]
        nombre, apellido = rng.choice(NOMBRES), rng.choice(APELLIDOS)
        base = f"{_ascii(nombre)}.{_ascii(apellido)}"
        correo = f"{base}{int(rng.integers(1, 999))}@{rng.choice(DOMINIOS)}"
        while correo in usados:
            correo = f"{base}{int(rng.integers(1, 9999))}@{rng.choice(DOMINIOS)}"
        usados.add(correo)
        ciudad = CIUDADES[rng.choice(len(CIUDADES), p=ciudades_p / ciudades_p.sum())]
        clientes.append(dict(
            segmento=seg[i], nombre=nombre, apellido=apellido, correo=correo,
            telefono=f"3{int(rng.integers(0, 3))}{int(rng.integers(0, 10))}{int(rng.integers(1_000_000, 9_999_999))}",
            ciudad=ciudad[0], departamento=ciudad[1],
            direccion=f"{rng.choice(['Cra.', 'Calle', 'Av.', 'Transversal'])} {int(rng.integers(1, 120))} "
                      f"#{int(rng.integers(1, 99))}-{int(rng.integers(1, 99))}",
            metodo=rng.choice(METODOS_PAGO[0], p=METODOS_PAGO[1]),
            talla=rng.choice(TALLAS[0], p=TALLAS[1]),
            tasa=s["tasa"] * float(rng.lognormal(0, 0.35)),
            alta=int(alta[i]),
            abandono=int(alta[i] + rng.exponential(s["abandono"])),
        ))
    return clientes


def simular_pedidos(clientes, productos, dias):
    n = len(dias)
    mult = multiplicador_diario(dias)
    tasa = np.array([c["tasa"] for c in clientes])[:, None]
    d_idx = np.arange(n)[None, :]
    alta = np.array([c["alta"] for c in clientes])[:, None]
    abandono = np.array([c["abandono"] for c in clientes])[:, None]
    actividad = np.where(d_idx < alta, 0.0, np.where(d_idx <= abandono, 1.0, 0.12))
    intensidad = tasa / 365.0 * mult[None, :] * actividad
    escala = PEDIDOS_OBJETIVO / intensidad.sum()          # calibra el volumen total
    prob = np.clip(intensidad * escala, 0, 0.9)
    compras = rng.random(prob.shape) < prob

    fechas_drop = np.array([(p["_fecha_drop"] - dias[0]).days for p in productos])
    seccion_prod = np.array([p["seccion_id"] for p in productos])
    popularidad = np.array([p["_popularidad"] for p in productos])
    horas = np.arange(24)
    p_hora = np.array([1, .5, .3, .2, .2, .3, .6, 1, 1.5, 2, 2.3, 2.6, 3, 3, 2.6, 2.4, 2.5, 2.8,
                       3.2, 3.8, 4.2, 4, 3, 1.8])
    p_hora = p_hora / p_hora.sum()

    pedidos = []
    for c_i, d_i in zip(*np.nonzero(compras)):
        c = clientes[c_i]
        s = SEGMENTOS[c["segmento"]]
        disponibles = np.nonzero(fechas_drop <= d_i)[0]
        if len(disponibles) == 0:
            continue
        antiguedad = d_i - fechas_drop[disponibles]
        peso = (np.array(s["seccion"])[seccion_prod[disponibles] - 1] * popularidad[disponibles]
                * (1 + 3 * np.exp(-antiguedad / 30)) * np.where(antiguedad > 300, 0.25, 1.0))
        n_items = int(rng.choice(s["items"][0], p=s["items"][1]))
        elegidos = rng.choice(disponibles, size=n_items, replace=True, p=peso / peso.sum())
        items = []
        for pi in elegidos:
            p = productos[pi]
            if p["seccion_id"] == 4:
                talla = "Única"
            elif rng.random() < 0.85:
                talla = c["talla"]
            else:
                talla = rng.choice(TALLAS[0], p=TALLAS[1])
            items.append(dict(producto_id=p["id"], nombre_producto=p["nombre_producto"], talla=str(talla),
                              cantidad=2 if rng.random() < 0.10 else 1, precio=p["precio"]))
        hora = int(rng.choice(horas, p=p_hora))
        fecha = datetime.combine(dias[d_i], datetime.min.time()) + timedelta(
            hours=hora, minutes=int(rng.integers(0, 60)), seconds=int(rng.integers(0, 60)))
        pedidos.append(dict(cliente=c, fecha=fecha, items=items))
    pedidos.sort(key=lambda p: p["fecha"])
    return pedidos


def _recortar(texto: str, n: int) -> str:
    return texto if len(texto) <= n else texto[: n - 1] + "…"


def armar_tablas(pedidos, productos, lanzamientos, clientes):
    filas_pedido, filas_items, filas_dir = [], [], []
    item_id = 0
    ultimo_dia = pedidos[-1]["fecha"].date()
    for pid, ped in enumerate(pedidos, start=1):
        c, items = ped["cliente"], ped["items"]
        r = rng.random()
        if (ultimo_dia - ped["fecha"].date()).days <= 2 and r < 0.5:
            estado = "PENDING"
        elif r < 0.90:
            estado = "APPROVED"
        elif r < 0.95:
            estado = "DECLINED"
        elif r < 0.99:
            estado = "VOIDED"
        else:
            estado = "ERROR"
        metodo = c["metodo"] if rng.random() < 0.85 else str(rng.choice(METODOS_PAGO[0]))
        total = sum(it["precio"] * it["cantidad"] for it in items)
        filas_pedido.append(dict(
            id=pid, nombre_cliente=c["nombre"], apellido_cliente=c["apellido"], correo_cliente=c["correo"],
            telefono_cliente=c["telefono"],
            nombre_producto=_recortar(", ".join(it["nombre_producto"] for it in items), 150),
            precio_producto=total, fecha_compra=ped["fecha"], metodo_pago=metodo,
            referencia_pago=f"UL-{ped['fecha']:%y%m%d}-{pid:05d}",
            estado_pago=estado,
            wompi_transaction_id=None if estado == "PENDING" else f"{int(rng.integers(10**5, 10**6))}-{int(rng.integers(10**9, 10**10))}",
            email_enviado=1 if estado == "APPROVED" else 0,
            talla=_recortar(", ".join(it["talla"] for it in items), 100),
            inventario_descontado=1 if estado == "APPROVED" else 0,
        ))
        for it in items:
            item_id += 1
            filas_items.append(dict(id=item_id, pedido_id=pid, producto_id=it["producto_id"],
                                    nombre_producto=it["nombre_producto"], talla=it["talla"],
                                    cantidad=it["cantidad"]))
        filas_dir.append(dict(id=pid, pedido_id=pid, pais="Colombia", municipio=c["departamento"],
                              ciudad=c["ciudad"], direccion=c["direccion"], fecha_registro=ped["fecha"]))

    secciones = pd.DataFrame([dict(id=i, nombre=n, orden=o, fecha_creacion=datetime(2024, 9, 20, 9, 0))
                              for i, n, o in SECCIONES])
    catalogo = pd.DataFrame([{k: v for k, v in p.items() if not k.startswith("_")} for p in productos])
    lanz = pd.DataFrame(lanzamientos)

    # Inscritos al drop programado: clientes recientes y activos.
    candidatos = [c for c in clientes if c["abandono"] > (FECHA_CORTE - FECHA_INICIO).days]
    elegidos = rng.choice(len(candidatos), size=min(160, len(candidatos)), replace=False)
    inscritos = pd.DataFrame([dict(
        id=i + 1, lanzamiento_id=int(lanz["id"].iloc[-1]), nombre=candidatos[k]["nombre"],
        apellido=candidatos[k]["apellido"], correo=candidatos[k]["correo"], telefono=candidatos[k]["telefono"],
        created_at=datetime(2026, 9, 26) + timedelta(hours=int(rng.integers(0, 96))), notificado_at=None,
    ) for i, k in enumerate(elegidos)])

    return {
        "secciones": secciones,
        "catalogo_productos": catalogo,
        "lanzamientos": lanz,
        "lanzamiento_inscritos": inscritos,
        "producto": pd.DataFrame(filas_pedido),
        "pedido_items": pd.DataFrame(filas_items),
        "direccion": pd.DataFrame(filas_dir),
    }


# ─────────────────────────────── exportación ───────────────────────────────
ORDEN_TABLAS = ["secciones", "catalogo_productos", "lanzamientos", "lanzamiento_inscritos",
                "producto", "pedido_items", "direccion"]


def _sql_valor(v) -> str:
    if v is None or (isinstance(v, float) and np.isnan(v)):
        return "NULL"
    if isinstance(v, (list, dict)):
        v = json.dumps(v, ensure_ascii=False)
    if isinstance(v, (datetime, pd.Timestamp)):
        return f"'{v:%Y-%m-%d %H:%M:%S}'"
    if isinstance(v, (bool, np.bool_)):
        return "1" if v else "0"
    if isinstance(v, (int, np.integer)):
        return str(int(v))
    if isinstance(v, (float, np.floating)):
        return f"{float(v):.2f}"
    texto = str(v).replace("\\", "\\\\").replace("'", "\\'")
    return f"'{texto}'"


def escribir_sql(tablas: dict, ruta):
    with open(ruta, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- Datos SINTÉTICOS generados por underlaw_ml/generar_datos.py (semilla fija).\n")
        f.write("-- NO son clientes ni ventas reales. Correr DESPUÉS de 01_esquema.sql.\n")
        # SQL_SAFE_UPDATES = 0: Workbench trae activo el "safe update mode", que
        # bloquea los DELETE sin WHERE con los que se vacían las tablas.
        f.write("USE underlaw_mineria;\nSET NAMES utf8mb4;\nSET FOREIGN_KEY_CHECKS = 0;\n"
                "SET @safe_updates_previo = @@SQL_SAFE_UPDATES;\nSET SQL_SAFE_UPDATES = 0;\n")
        for nombre in reversed(ORDEN_TABLAS):
            f.write(f"DELETE FROM {nombre};\n")
        for nombre in ORDEN_TABLAS:
            df = tablas[nombre]
            cols = ", ".join(df.columns)
            filas = df.to_dict("records")
            for i in range(0, len(filas), 400):
                bloque = filas[i:i + 400]
                valores = ",\n".join("(" + ", ".join(_sql_valor(r[c]) for c in df.columns) + ")" for r in bloque)
                f.write(f"INSERT INTO {nombre} ({cols}) VALUES\n{valores};\n")
        f.write("SET FOREIGN_KEY_CHECKS = 1;\nSET SQL_SAFE_UPDATES = @safe_updates_previo;\n")


def exportar(tablas: dict):
    DIR_EXPORT.mkdir(parents=True, exist_ok=True)
    for nombre, df in tablas.items():
        salida = df.copy()
        for col in salida.columns:
            if salida[col].map(lambda v: isinstance(v, (list, dict))).any():
                salida[col] = salida[col].map(lambda v: json.dumps(v, ensure_ascii=False))
        salida.to_csv(DIR_EXPORT / f"{nombre}.csv", index=False, encoding="utf-8")
    with pd.ExcelWriter(DIR_EXPORT / "evidencia.xlsx") as xls:
        for nombre in ORDEN_TABLAS:
            df = pd.read_csv(DIR_EXPORT / f"{nombre}.csv")
            df.to_excel(xls, sheet_name=nombre[:31], index=False)
    escribir_sql(tablas, DIR_SQL / "02_datos.sql")


def generar() -> dict:
    dias = [FECHA_INICIO + timedelta(days=i) for i in range((FECHA_CORTE - FECHA_INICIO).days + 1)]
    productos, lanzamientos = construir_catalogo()
    clientes = construir_clientes(len(dias))
    pedidos = simular_pedidos(clientes, productos, dias)
    return armar_tablas(pedidos, productos, lanzamientos, clientes)


if __name__ == "__main__":
    tablas = generar()
    exportar(tablas)
    ped = tablas["producto"]
    print("Datos sintéticos generados (semilla", SEMILLA, ")")
    for nombre in ORDEN_TABLAS:
        print(f"  {nombre:<22} {len(tablas[nombre]):>6} filas")
    print("  pedidos por estado:", ped["estado_pago"].value_counts().to_dict())
    print("  clientes con al menos un pedido:", ped["correo_cliente"].nunique())
    print("  periodo:", ped["fecha_compra"].min(), "a", ped["fecha_compra"].max())
