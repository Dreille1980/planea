#!/bin/bash
# Migration automatique vers PlaneaTypography
# Pour tous les fichiers Views Swift non encore migrés

echo "🎨 Migration Typography - Planea Design System"
echo ""

# Liste des fichiers déjà migrés (à exclure)
MIGRATED=(
    "GenerateMealPlanView.swift"
    "WeekOverviewView.swift"
    "RecipeDetailView.swift"
    "SavedRecipesView.swift"
    "ShoppingListView.swift"
    "ChatView.swift"
)

# Fonction pour checker si un fichier est migré
is_migrated() {
    local file=$1
    for migrated in "${MIGRATED[@]}"; do
        if [[ $file == *"$migrated"* ]]; then
            return 0
        fi
    done
    return 1
}

# Trouver tous les fichiers Swift dans Views
find Planea-iOS/Planea/Planea/Views -name "*.swift" -type f | while read file; do
    if is_migrated "$file"; then
        echo "⏭️  Skip: $(basename "$file") (already migrated)"
        continue
    fi
    
    echo "🔄 Migrating: $(basename "$file")"
    
    # Backup
    cp "$file" "$file.bak"
    
    # Typography migrations
    sed -i '' 's/\.font(\.largeTitle)/\.font(.planeaLargeTitle)/g' "$file"
    sed -i '' 's/\.font(\.title)/\.font(.planeaTitle1)/g' "$file"
    sed -i '' 's/\.font(\.title2)/\.font(.planeaTitle2)/g' "$file"
    sed -i '' 's/\.font(\.title3)/\.font(.planeaTitle3)/g' "$file"
    sed -i '' 's/\.font(\.headline)\.bold()/\.font(.planeaHeadline)/g' "$file"
    sed -i '' 's/\.font(\.headline)/\.font(.planeaHeadline)/g' "$file"
    sed -i '' 's/\.font(\.subheadline)/\.font(.planeaSubheadline)/g' "$file"
    sed -i '' 's/\.font(\.body)/\.font(.planeaBody)/g' "$file"
    sed -i '' 's/\.font(\.callout)/\.font(.planeaCallout)/g' "$file"
    sed -i '' 's/\.font(\.footnote)/\.font(.planeaFootnote)/g' "$file"
    sed -i '' 's/\.font(\.caption)/\.font(.planeaCaption)/g' "$file"
    sed -i '' 's/\.font(\.caption2)/\.font(.planeaCaption2)/g' "$file"
    
    # Color migrations
    sed -i '' 's/\.foregroundStyle(\.secondary)/\.foregroundColor(.planeaTextSecondary)/g' "$file"
    sed -i '' 's/\.foregroundStyle(\.primary)/\.foregroundColor(.planeaTextPrimary)/g' "$file"
    sed -i '' 's/\.foregroundColor(\.secondary)/\.foregroundColor(.planeaTextSecondary)/g' "$file"
    
    # Common spacing patterns (be careful not to break existing code)
    sed -i '' 's/\.padding(20)/\.padding(PlaneaSpacing.lg)/g' "$file"
    sed -i '' 's/\.padding(16)/\.padding(PlaneaSpacing.md)/g' "$file"
    sed -i '' 's/\.padding(12)/\.padding(PlaneaSpacing.sm)/g' "$file"
    sed -i '' 's/spacing: 20/spacing: PlaneaSpacing.lg/g' "$file"
    sed -i '' 's/spacing: 16/spacing: PlaneaSpacing.md/g' "$file"
    sed -i '' 's/spacing: 12/spacing: PlaneaSpacing.sm/g' "$file"
    
    echo "✅ Migrated: $(basename "$file")"
done

echo ""
echo "🎉 Migration complete!"
echo "   Review changes with: git diff"
echo "   Remove backups with: find . -name '*.swift.bak' -delete"
