#!/bin/bash
# Generate env.json from environment variables for Flutter builds

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
  echo "Error: SUPABASE_URL and SUPABASE_KEY environment variables must be set"
  exit 1
fi

echo "{\"SUPABASE_URL\":\"$SUPABASE_URL\",\"SUPABASE_KEY\":\"$SUPABASE_KEY\"}" > env.json
echo "env.json generated successfully"
