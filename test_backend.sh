#!/bin/bash

echo "🔍 Diagnostic du backend Planea sur Render"
echo "==========================================="
echo ""

BACKEND_URL="https://planea-backend.onrender.com"

# Test 1: Health check
echo "📡 Test 1: Health check..."
echo "URL: $BACKEND_URL/health"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" --connect-timeout 10 --max-time 30 "$BACKEND_URL/health" 2>&1)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Health check OK (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
else
    echo "❌ Health check FAILED (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
fi
echo ""

# Test 2: Meal prep concepts endpoint
echo "📡 Test 2: Meal prep concepts endpoint..."
echo "URL: $BACKEND_URL/ai/meal-prep-concepts"
CONCEPTS_RESPONSE=$(curl -s -w "\n%{http_code}" --connect-timeout 10 --max-time 60 \
  -X POST "$BACKEND_URL/ai/meal-prep-concepts" \
  -H "Content-Type: application/json" \
  -d '{
    "language": "fr",
    "constraints": {
      "diet": "omnivore",
      "evict": []
    }
  }' 2>&1)

HTTP_CODE=$(echo "$CONCEPTS_RESPONSE" | tail -n1)
BODY=$(echo "$CONCEPTS_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Concepts endpoint OK (HTTP $HTTP_CODE)"
    echo "   Response preview: $(echo "$BODY" | head -c 200)..."
else
    echo "❌ Concepts endpoint FAILED (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
fi
echo ""

# Test 3: Meal prep kits endpoint
echo "📡 Test 3: Meal prep kits endpoint..."
echo "URL: $BACKEND_URL/ai/meal-prep-kits"
KITS_RESPONSE=$(curl -s -w "\n%{http_code}" --connect-timeout 10 --max-time 120 \
  -X POST "$BACKEND_URL/ai/meal-prep-kits" \
  -H "Content-Type: application/json" \
  -d '{
    "days": ["Mon", "Tue"],
    "meals": ["lunch", "dinner"],
    "servings_per_meal": 4,
    "total_prep_time_preference": "1h30",
    "skill_level": "intermediate",
    "avoid_rare_ingredients": false,
    "prefer_long_shelf_life": false,
    "constraints": {
      "diet": "omnivore",
      "evict": []
    },
    "units": "metric",
    "language": "fr"
  }' 2>&1)

HTTP_CODE=$(echo "$KITS_RESPONSE" | tail -n1)
BODY=$(echo "$KITS_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Kits endpoint OK (HTTP $HTTP_CODE)"
    echo "   Response preview: $(echo "$BODY" | head -c 200)..."
else
    echo "❌ Kits endpoint FAILED (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
fi
echo ""

# Summary
echo "==========================================="
echo "📊 Résumé du diagnostic:"
echo ""
echo "Note: Si le backend est en veille (cold start),"
echo "le premier appel peut prendre 30-60 secondes."
echo ""
echo "Pour réveiller le backend, visitez:"
echo "https://planea-backend.onrender.com/health"
echo ""
