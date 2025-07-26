#!/bin/bash
cd /workspaces/legezhixiao/backend
export PORT=3001
export NODE_ENV=development
node -r ts-node/register --experimental-specifier-resolution=node src/server.ts
