#!/bin/bash
# ==============================================================================
# User Data Script para Amazon Linux 2023 - Cascos Ultra (Black Friday)
# Configura NGINX e inyecta dinámicamente los metadatos de la instancia
# ==============================================================================

# 1. Actualizar sistema e instalar NGINX y utilidades
dnf update -y
dnf install -y nginx stress-ng

# 2. Consultar AWS IMDSv2 (Instance Metadata Service v2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
LOCAL_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

# 3. Configurar Headers en NGINX para inspección HTTP
cat <<EOF > /etc/nginx/conf.d/headers.conf
add_header X-Served-By "$INSTANCE_ID" always;
add_header X-Availability-Zone "$AZ" always;
add_header X-Local-IP "$LOCAL_IP" always;
EOF

# 4. Descargar o generar el archivo HTML con los metadatos reales inyectados
# (Reemplazando los placeholders con las variables extraídas de IMDSv2)
cat <<'EOF' > /tmp/template.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cascos Ultra | Black Friday - Prueba de Escalamiento AWS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@600;800;900&family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-base: #0a0b10;
            --bg-surface: #12141f;
            --bg-card: #181b2a;
            --accent-red: #ff334b;
            --accent-red-glow: rgba(255, 51, 75, 0.4);
            --accent-green: #00ff88;
            --accent-cyan: #00e5ff;
            --text-main: #f3f4f6;
            --text-muted: #9ca3af;
            --border-color: #262b42;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Inter', sans-serif; background-color: var(--bg-base); color: var(--text-main); min-height: 100vh; display: flex; flex-direction: column; }
        .top-ticker { background: linear-gradient(90deg, #ff334b, #99001f); color: white; font-size: 0.82rem; font-weight: 700; letter-spacing: 1.5px; padding: 8px 15px; text-align: center; text-transform: uppercase; display: flex; align-items: center; justify-content: center; gap: 12px; }
        .pulse-dot { width: 8px; height: 8px; background-color: #fff; border-radius: 50%; display: inline-block; animation: pulse 1s infinite alternate; }
        @keyframes pulse { from { opacity: 0.4; transform: scale(0.8); } to { opacity: 1; transform: scale(1.3); } }
        header { background-color: rgba(18, 20, 31, 0.85); backdrop-filter: blur(12px); border-bottom: 1px solid var(--border-color); position: sticky; top: 0; z-index: 100; padding: 15px 5%; display: flex; justify-content: space-between; align-items: center; }
        .brand { display: flex; align-items: center; gap: 10px; text-decoration: none; }
        .brand-text { font-family: 'Orbitron', sans-serif; font-size: 1.4rem; font-weight: 900; color: white; }
        .brand-text span { color: var(--accent-red); }
        .badge-live { background: rgba(0, 255, 136, 0.1); border: 1px solid var(--accent-green); color: var(--accent-green); padding: 5px 12px; border-radius: 20px; font-size: 0.8rem; font-weight: 600; display: flex; align-items: center; gap: 6px; }
        .container { max-width: 1200px; margin: 0 auto; padding: 30px 20px; width: 100%; }
        .server-inspector { background: linear-gradient(135deg, #161928, #10121d); border: 2px solid var(--accent-cyan); border-radius: 16px; padding: 24px 28px; margin-bottom: 40px; box-shadow: 0 10px 30px rgba(0, 229, 255, 0.12); position: relative; }
        .server-inspector::before { content: 'AWS AUTO SCALING ACTIVE'; position: absolute; top: 12px; right: 20px; font-family: 'Orbitron', sans-serif; font-size: 0.65rem; color: var(--accent-cyan); letter-spacing: 2px; }
        .inspector-title { display: flex; align-items: center; gap: 12px; margin-bottom: 20px; }
        .inspector-title h2 { font-family: 'Orbitron', sans-serif; font-size: 1.25rem; color: white; }
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; }
        .metric-card { background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.07); border-radius: 10px; padding: 14px 18px; }
        .metric-label { font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 6px; }
        .metric-value { font-family: monospace; font-size: 1.15rem; font-weight: 700; color: #fff; }
        .metric-value.highlight { color: var(--accent-green); text-shadow: 0 0 10px rgba(0, 255, 136, 0.4); }
        .refresh-zone { margin-top: 20px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px; padding-top: 16px; border-top: 1px solid rgba(255, 255, 255, 0.08); }
        .btn-test { background: linear-gradient(135deg, var(--accent-cyan), #0088cc); color: #040914; font-weight: 700; padding: 10px 20px; border: none; border-radius: 8px; cursor: pointer; }
        .hero { text-align: center; margin-bottom: 50px; }
        .hero h1 { font-family: 'Orbitron', sans-serif; font-size: clamp(2rem, 5vw, 3.5rem); margin-bottom: 12px; }
        .products-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 25px; }
        .product-card { background-color: var(--bg-card); border: 1px solid var(--border-color); border-radius: 14px; padding: 20px; text-align: center; }
        .product-img { font-size: 4rem; margin-bottom: 10px; }
        .price { font-family: 'Orbitron', sans-serif; font-size: 1.4rem; color: var(--accent-green); font-weight: 800; margin-top: 10px; }
        .old-price { color: #6b7280; text-decoration: line-through; font-size: 0.9rem; }
        footer { margin-top: auto; background-color: var(--bg-surface); border-top: 1px solid var(--border-color); padding: 25px; text-align: center; font-size: 0.85rem; color: var(--text-muted); }
    </style>
</head>
<body>
    <div class="top-ticker">
        <span class="pulse-dot"></span>
        <span>BLACK FRIDAY CASCOS ULTRA &bull; TRÁFICO SIMULADO EN VIVO &bull; AWS FREE TIER</span>
        <span class="pulse-dot"></span>
    </div>
    <header>
        <div class="brand">
            <span style="font-size:1.8rem">🪖</span>
            <div class="brand-text">CASCOS<span>ULTRA</span></div>
        </div>
        <div class="badge-live">
            <span class="pulse-dot" style="background-color: var(--accent-green);"></span>
            <span>NODO ONLINE</span>
        </div>
    </header>
    <div class="container">
        <section class="server-inspector">
            <div class="inspector-title">
                <span style="font-size: 1.6rem;">⚡</span>
                <h2>Servidor Web que te Atiende</h2>
            </div>
            <div class="metrics-grid">
                <div class="metric-card">
                    <div class="metric-label">🏷️ Instance ID (EC2)</div>
                    <div class="metric-value highlight">__INSTANCE_ID__</div>
                </div>
                <div class="metric-card">
                    <div class="metric-label">🌐 Availability Zone</div>
                    <div class="metric-value">__AZ__</div>
                </div>
                <div class="metric-card">
                    <div class="metric-label">🔒 IP Privada del Host</div>
                    <div class="metric-value">__LOCAL_IP__</div>
                </div>
                <div class="metric-card">
                    <div class="metric-label">⚙️ Servidor Web</div>
                    <div class="metric-value">NGINX 1.24 (AL2023)</div>
                </div>
            </div>
            <div class="refresh-zone">
                <div style="font-size:0.85rem; color:#9ca3af;">
                    💡 <em>Recarga para consultar al Application Load Balancer (ALB) y verificar el escalamiento horizontal.</em>
                </div>
                <button class="btn-test" onclick="window.location.reload(true);">🔄 Probar Balanceo (Recargar)</button>
            </div>
        </section>
        <section class="hero">
            <h1>Protección Extrema<br><span style="color:var(--accent-red)">50% OFF Black Friday</span></h1>
            <p>Cascos de alta gama probando la elasticidad horizontal en AWS EC2.</p>
        </section>
        <div class="products-grid">
            <div class="product-card">
                <div class="product-img">🏎️</div>
                <h3>Ultra Carbon Track Pro</h3>
                <div class="old-price">$499 USD</div>
                <div class="price">$249 USD</div>
            </div>
            <div class="product-card">
                <div class="product-img">🏍️</div>
                <h3>Adventure GT Modular</h3>
                <div class="old-price">$360 USD</div>
                <div class="price">$199 USD</div>
            </div>
            <div class="product-card">
                <div class="product-img">⚡</div>
                <h3>Titan Enduro MX-Apex</h3>
                <div class="old-price">$320 USD</div>
                <div class="price">$145 USD</div>
            </div>
        </div>
    </div>
    <footer>
        <p><strong>Cascos Ultra &copy; 2026</strong> &bull; AWS VPC 10.0.0.0/16 &bull; 3 Subredes Públicas &bull; ALB + Target Tracking ASG</p>
    </footer>
</body>
</html>
EOF

# 5. Sustituir variables y mover a la ruta pública de NGINX
sed -e "s/__INSTANCE_ID__/$INSTANCE_ID/g" \
    -e "s/__AZ__/$AZ/g" \
    -e "s/__LOCAL_IP__/$LOCAL_IP/g" \
    /tmp/template.html > /usr/share/nginx/html/index.html

# 6. Iniciar y habilitar NGINX
systemctl restart nginx
systemctl enable nginx
