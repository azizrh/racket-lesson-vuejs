# S-Expression Practice App

A Vue.js + Vite application for practicing S-expressions with real-time validation.

## Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

## Docker

```bash
# Development with Docker
docker-compose --profile development up

# Production with Docker
npm run build
docker-compose --profile production up
```

## Project Structure

```
s-expression-vite/
├── src/
│   ├── components/     # Vue components
│   ├── App.vue        # Main app component
│   ├── main.js        # Entry point
│   └── style.css      # Global styles
├── public/            # Static assets
├── index.html         # HTML entry point
└── vite.config.js     # Vite configuration
```
