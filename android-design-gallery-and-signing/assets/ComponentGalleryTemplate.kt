package com.example.app.debug.gallery

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.displayCutout
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

/**
 * Gallery data is injected so development fixtures never become the production contract.
 */
enum class GalleryScenario { POPULATED, LONG_EDGE_CASES, EMPTY, LOADING, ERROR }

data class GalleryItem(
    val id: String,
    val title: String,
    val subtitle: String,
    val badgeText: String
)

interface GalleryDataSource {
    fun itemsFor(scenario: GalleryScenario): List<GalleryItem>
}

/** Install this implementation only from debug/preview DI bindings. */
object DevelopmentGalleryDataSource : GalleryDataSource {
    private val standardItems = listOf(
        GalleryItem("1", "Primary Action Card", "Standard subtitle with balanced length", "ACTIVE"),
        GalleryItem("2", "Secondary Item", "Verifies spacing, elevation, and typography tokens", "NEW")
    )

    private val edgeCaseItems = listOf(
        GalleryItem(
            id = "edge-1",
            title = "Extremely Long Unbroken & Multi-Line Title To Verify Ellipsis And Prevent Horizontal Cutoff Across High-Density Displays",
            subtitle = "Includes CJK (你好世界), emoji (🚀📱), and tall glyphs to verify line-height and top/bottom padding clipping.",
            badgeText = "999+ DAYS"
        )
    )

    override fun itemsFor(scenario: GalleryScenario) = when (scenario) {
        GalleryScenario.POPULATED -> standardItems
        GalleryScenario.LONG_EDGE_CASES -> edgeCaseItems
        GalleryScenario.EMPTY, GalleryScenario.LOADING, GalleryScenario.ERROR -> emptyList()
    }
}

enum class GalleryThemeMode { SYSTEM, LIGHT, DARK, DYNAMIC }

data class GalleryThemeConfiguration(
    val mode: GalleryThemeMode,
    val colorSchemeName: String = "App default",
    val dynamicColorAvailable: Boolean
)

/**
 * Shared Component Gallery Screen:
 * Renders all shared UI components under live Theme + Dummy Data scenario toggles
 * and displays current WindowInsets (Status Bar, Cutout, Bottom Nav) for visual verification.
 */
@Composable
fun ComponentGalleryScreen(
    dataSource: GalleryDataSource,
    dynamicColorAvailable: Boolean,
    colorSchemeNames: List<String> = listOf("App default"),
    appThemeWrapper: @Composable (GalleryThemeConfiguration, @Composable () -> Unit) -> Unit
) {
    require(colorSchemeNames.isNotEmpty()) { "Provide at least one gallery color scheme" }
    var themeMode by remember { mutableStateOf(GalleryThemeMode.SYSTEM) }
    var colorSchemeName by remember { mutableStateOf(colorSchemeNames.first()) }
    var scenario by remember { mutableStateOf(GalleryScenario.POPULATED) }

    appThemeWrapper(
        GalleryThemeConfiguration(themeMode, colorSchemeName, dynamicColorAvailable)
    ) {
        Scaffold(
            contentWindowInsets = WindowInsets.safeDrawing
        ) { innerPadding ->
            val statusTop = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
            val navBottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
            val cutoutTop = WindowInsets.displayCutout.asPaddingValues().calculateTopPadding()

            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    Text(
                        text = "Shared Component & Theme Gallery",
                        style = MaterialTheme.typography.headlineSmall
                    )
                    Text(
                        text = "Insets — StatusBar: $statusTop | Cutout: $cutoutTop | BottomNav: $navBottom",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                item {
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        GalleryThemeMode.entries.forEach { mode ->
                            val enabled = mode != GalleryThemeMode.DYNAMIC || dynamicColorAvailable
                            FilterChip(
                                selected = themeMode == mode,
                                enabled = enabled,
                                onClick = { themeMode = mode },
                                label = { Text(if (enabled) mode.name else "DYNAMIC (unavailable)") }
                            )
                        }
                        colorSchemeNames.forEach { name ->
                            FilterChip(
                                selected = colorSchemeName == name,
                                onClick = { colorSchemeName = name },
                                label = { Text(name) }
                            )
                        }
                        GalleryScenario.entries.forEach { mode ->
                            FilterChip(
                                selected = scenario == mode,
                                onClick = { scenario = mode },
                                label = { Text(mode.name) }
                            )
                        }
                    }
                }

                // Section 1: Buttons & Touch Targets (>= 48dp)
                item {
                    GallerySection(title = "Buttons & CTAs") {
                        FlowRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            Button(onClick = {}) { Text("Primary CTA") }
                            OutlinedButton(onClick = {}) { Text("Secondary") }
                            Button(onClick = {}, enabled = false) { Text("Disabled") }
                        }
                    }
                }

                // Section 2: Shared Cards with Dummy Data Scenarios
                item {
                    GallerySection(title = "Shared Cards (${scenario.name})") {
                        val items = dataSource.itemsFor(scenario)
                        when (scenario) {
                            GalleryScenario.EMPTY -> Text("Empty State Component Preview")
                            GalleryScenario.LOADING -> Text("Loading State Component Preview")
                            GalleryScenario.ERROR -> Text(
                                text = "Error State Component Preview — Retry Action",
                                color = MaterialTheme.colorScheme.error
                            )
                            else -> Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                items.forEach { item ->
                                    Card(modifier = Modifier.fillMaxWidth()) {
                                        Column(modifier = Modifier.padding(16.dp)) {
                                            Text(
                                                text = item.title,
                                                style = MaterialTheme.typography.titleMedium,
                                                maxLines = 2,
                                                overflow = TextOverflow.Ellipsis
                                            )
                                            Spacer(modifier = Modifier.height(4.dp))
                                            Text(
                                                text = item.subtitle,
                                                style = MaterialTheme.typography.bodyMedium,
                                                maxLines = 3,
                                                overflow = TextOverflow.Ellipsis
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun GallerySection(
    title: String,
    content: @Composable () -> Unit
) {
    Surface(
        tonalElevation = 2.dp,
        shape = MaterialTheme.shapes.medium,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(12.dp))
            content()
        }
    }
}

/**
 * Subtle but obvious entry point for dev/debug builds.
 * Renders an unobtrusive, low-contrast floating trigger in a corner that never breaks or
 * obstructs the production UI design. Wrap your root app scaffold in this when in DEBUG mode.
 */
@Composable
fun DevGalleryEntryOverlay(
    isDevBuild: Boolean, // e.g. BuildConfig.DEBUG
    onOpenGallery: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    androidx.compose.foundation.layout.Box(modifier = modifier.fillMaxSize()) {
        content()
        if (isDevBuild) {
            Surface(
                onClick = onOpenGallery,
                shape = androidx.compose.foundation.shape.CircleShape,
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.75f),
                contentColor = MaterialTheme.colorScheme.onSurfaceVariant,
                tonalElevation = 1.dp,
                modifier = Modifier
                    .padding(WindowInsets.statusBars.asPaddingValues())
                    .padding(top = 4.dp, end = 8.dp)
                    .align(androidx.compose.ui.Alignment.TopEnd)
            ) {
                Text(
                    text = "⚙ Gallery",
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                )
            }
        }
    }
}

