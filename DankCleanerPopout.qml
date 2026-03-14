import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

Item {
    id: root

    readonly property int pad: Theme.spacingS

    function maxDiskRowSize() {
        var rows = CleanerService.diskTopDirs || [];
        if (rows.length === 0)
            return 1;
        var maxV = rows[0].size || 1;
        return Math.max(1, maxV);
    }

    function pieColor(index) {
        var palette = [Theme.primary, "#4CAF50", "#FF9800", "#03A9F4", "#AB47BC", "#EF5350"];
        return palette[index % palette.length];
    }

    DankTabBar {
        id: tabBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: pad
        anchors.rightMargin: pad
        currentIndex: 0
        model: [
            {
                text: "Cleanup",
                icon: "cleaning_services"
            },
            {
                text: "Large Files",
                icon: "folder_open"
            },
            {
                text: "Disk Analyzer",
                icon: "pie_chart"
            }
        ]
        onTabClicked: function (index) {
            tabBar.currentIndex = index;
        }
    }

    // ─── Tab 0: Cleanup ───────────────────────────────────────────────────────

    Item {
        id: cleanupTab
        visible: tabBar.currentIndex === 0
        anchors.top: tabBar.bottom
        anchors.topMargin: pad
        anchors.left: parent.left
        anchors.leftMargin: pad
        anchors.right: parent.right
        anchors.rightMargin: pad
        anchors.bottom: parent.bottom

        // Header card
        Rectangle {
            id: headerCard
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 72
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Row {
                anchors.fill: parent
                anchors.margins: pad
                spacing: pad

                Column {
                    width: parent.width - rescanButton.width - pad
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    StyledText {
                        text: "Reclaimable space: " + CleanerService.formatBytes(CleanerService.totalCleanupBytes)
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: CleanerService.statusText + " • Last clean: " + CleanerService.lastCleanupLabel
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        width: parent.width
                        elide: Text.ElideRight
                    }
                }

                DankButton {
                    id: rescanButton
                    text: "Rescan"
                    iconName: "refresh"
                    enabled: !CleanerService.running
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: CleanerService.refreshAll()
                }
            }
        }

        // Clean Now button — anchored to bottom
        DankButton {
            id: cleanNowButton
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            text: CleanerService.running ? "Working..." : "Clean Now"
            iconName: "auto_fix_high"
            enabled: !CleanerService.running
            onClicked: CleanerService.cleanNow()
        }

        // Stat cards grid — between header and Clean Now button
        GridLayout {
            anchors.top: headerCard.bottom
            anchors.topMargin: pad
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: cleanNowButton.top
            anchors.bottomMargin: pad
            columns: 2
            columnSpacing: pad
            rowSpacing: pad

            Repeater {
                model: [
                    {
                        label: "User Cache",
                        enabled: CleanerService.cleanupCache,
                        value: CleanerService.cacheBytes
                    },
                    {
                        label: "Trash",
                        enabled: CleanerService.cleanupTrash,
                        value: CleanerService.trashBytes
                    },
                    {
                        label: "Browser Cache",
                        enabled: CleanerService.cleanupBrowserCache,
                        value: CleanerService.browserCacheBytes
                    },
                    {
                        label: "Old /tmp (user only)",
                        enabled: CleanerService.cleanupTmp,
                        value: CleanerService.tmpBytes
                    }
                ]

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    // ON/OFF badge — top-right corner
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 6
                        anchors.rightMargin: 6
                        width: badgeText.implicitWidth + 8
                        height: badgeText.implicitHeight + 4
                        radius: 4
                        color: modelData.enabled ? Theme.primary : Theme.surfaceVariant

                        StyledText {
                            id: badgeText
                            anchors.centerIn: parent
                            text: modelData.enabled ? "ON" : "OFF"
                            font.pixelSize: Theme.fontSizeXSmall
                            font.weight: Font.SemiBold
                            color: modelData.enabled ? Theme.surfaceContainerHigh : Theme.surfaceVariantText
                        }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: pad
                        anchors.rightMargin: pad
                        spacing: 2

                        StyledText {
                            text: modelData.label
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: CleanerService.formatBytes(modelData.value)
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: modelData.enabled ? Theme.primary : Theme.surfaceVariantText
                        }
                    }
                }
            }
        }
    }

    // ─── Tab 1: Large Files ───────────────────────────────────────────────────

    Item {
        id: largeFilesTab
        visible: tabBar.currentIndex === 1
        anchors.top: tabBar.bottom
        anchors.topMargin: pad
        anchors.left: parent.left
        anchors.leftMargin: pad
        anchors.right: parent.right
        anchors.rightMargin: pad
        anchors.bottom: parent.bottom

        // Header row
        Row {
            id: lfHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Theme.spacingM

            StyledText {
                text: "Large files (" + CleanerService.largeFiles.length + ")"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: Theme.surfaceText
            }

            StyledText {
                text: "Threshold: " + CleanerService.largeFileThresholdMb + " MB"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Divider
        Rectangle {
            id: lfDivider
            anchors.top: lfHeader.bottom
            anchors.topMargin: pad
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.surfaceVariant
        }

        // File list
        Flickable {
            anchors.top: lfDivider.bottom
            anchors.topMargin: pad
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            contentHeight: filesColumn.implicitHeight

            Column {
                id: filesColumn
                width: parent.width
                spacing: 2

                Repeater {
                    model: CleanerService.largeFiles

                    Rectangle {
                        required property var modelData
                        required property int index
                        width: filesColumn.width
                        height: 44
                        radius: 6
                        color: index % 2 === 0 ? "transparent" : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.25)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: pad

                            Column {
                                width: Math.max(120, parent.width - sizeText.width - deleteButton.width - pad * 2)
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                StyledText {
                                    text: modelData.path
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    elide: Text.ElideMiddle
                                    width: parent.width
                                }

                                StyledText {
                                    text: "Modified: " + new Date(modelData.mtime * 1000).toLocaleString()
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeXSmall
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }

                            StyledText {
                                id: sizeText
                                text: CleanerService.formatBytes(modelData.size)
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.primary
                                font.pixelSize: Theme.fontSizeSmall
                                width: 70
                                horizontalAlignment: Text.AlignRight
                            }

                            DankButton {
                                id: deleteButton
                                text: "Delete"
                                iconName: "delete"
                                width: 92
                                anchors.verticalCenter: parent.verticalCenter
                                enabled: !CleanerService.running
                                onClicked: CleanerService.removeLargeFile(modelData.path)
                            }
                        }
                    }
                }

                Rectangle {
                    visible: CleanerService.largeFiles.length === 0
                    width: parent.width
                    height: 80
                    color: "transparent"
                    StyledText {
                        anchors.centerIn: parent
                        text: CleanerService.running ? "Scanning..." : "No large files found in selected folders."
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }
    }

    // ─── Tab 2: Disk Analyzer ─────────────────────────────────────────────────

    Item {
        id: diskTab
        visible: tabBar.currentIndex === 2
        anchors.top: tabBar.bottom
        anchors.topMargin: pad
        anchors.left: parent.left
        anchors.leftMargin: pad
        anchors.right: parent.right
        anchors.rightMargin: pad
        anchors.bottom: parent.bottom

        // Header row
        Row {
            id: diskHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Theme.spacingM

            StyledText {
                text: "Disk usage: " + CleanerService.formatBytes(CleanerService.diskTotalBytes)
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: Theme.surfaceText
            }

            DankButton {
                text: "Analyze"
                iconName: "refresh"
                enabled: !CleanerService.running
                onClicked: CleanerService.scanDiskUsage()
            }
        }

        // Panels row
        Row {
            anchors.top: diskHeader.bottom
            anchors.topMargin: pad
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: pad

            // Left panel — top directories
            Rectangle {
                width: parent.width * 0.62
                height: parent.height
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Column {
                    anchors.fill: parent
                    anchors.margins: pad
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "Top directories"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    Flickable {
                        width: parent.width
                        height: parent.height - 24
                        contentHeight: diskBars.implicitHeight
                        clip: true

                        Column {
                            id: diskBars
                            width: parent.width
                            spacing: Theme.spacingXS

                            Repeater {
                                model: CleanerService.diskTopDirs

                                Column {
                                    required property var modelData
                                    width: diskBars.width
                                    spacing: 2

                                    StyledText {
                                        width: parent.width
                                        text: modelData.path
                                        elide: Text.ElideMiddle
                                        font.pixelSize: Theme.fontSizeXSmall
                                        color: Theme.surfaceVariantText
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 10
                                        radius: 5
                                        color: Theme.surfaceVariant

                                        Rectangle {
                                            width: Math.max(2, parent.width * (modelData.size / root.maxDiskRowSize()))
                                            height: parent.height
                                            radius: parent.radius
                                            color: Theme.primary
                                        }
                                    }

                                    StyledText {
                                        text: CleanerService.formatBytes(modelData.size)
                                        font.pixelSize: Theme.fontSizeXSmall
                                        color: Theme.surfaceText
                                    }
                                }
                            }

                            Rectangle {
                                visible: CleanerService.diskTopDirs.length === 0
                                width: parent.width
                                height: 80
                                color: "transparent"
                                StyledText {
                                    anchors.centerIn: parent
                                    text: CleanerService.running ? "Analyzing..." : "No disk data available."
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                            }
                        }
                    }
                }
            }

            // Right panel — pie chart + legend
            Rectangle {
                width: parent.width - parent.width * 0.62 - pad
                height: parent.height
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Column {
                    anchors.fill: parent
                    anchors.margins: pad
                    spacing: pad

                    StyledText {
                        text: "Category split"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    Canvas {
                        id: pieCanvas
                        width: Math.min(parent.width, 140)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var buckets = CleanerService.diskCategoryBuckets || [];
                            var total = 0;
                            for (var i = 0; i < buckets.length; i++)
                                total += buckets[i].size;
                            if (total <= 0)
                                return;

                            var cx = width / 2;
                            var cy = height / 2;
                            var r = Math.min(cx, cy) - 4;
                            var start = -Math.PI / 2;

                            for (var j = 0; j < buckets.length; j++) {
                                var part = buckets[j].size / total;
                                var end = start + (Math.PI * 2 * part);
                                ctx.beginPath();
                                ctx.moveTo(cx, cy);
                                ctx.arc(cx, cy, r, start, end, false);
                                ctx.closePath();
                                ctx.fillStyle = root.pieColor(j);
                                ctx.fill();
                                start = end;
                            }

                            ctx.beginPath();
                            ctx.arc(cx, cy, r * 0.5, 0, Math.PI * 2, false);
                            ctx.fillStyle = Theme.surfaceContainerHigh;
                            ctx.fill();
                        }

                        Connections {
                            target: CleanerService
                            function onDiskCategoryBucketsChanged() {
                                pieCanvas.requestPaint();
                            }
                        }
                    }

                    Flickable {
                        width: parent.width
                        height: parent.height - pieCanvas.height - 44
                        contentHeight: legendColumn.implicitHeight
                        clip: true

                        Column {
                            id: legendColumn
                            width: parent.width
                            spacing: Theme.spacingXS

                            Repeater {
                                model: CleanerService.diskCategoryBuckets
                                Row {
                                    required property var modelData
                                    required property int index
                                    width: legendColumn.width
                                    spacing: Theme.spacingXS

                                    Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: root.pieColor(index)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        width: parent.width - 16
                                        text: modelData.name + " • " + CleanerService.formatBytes(modelData.size)
                                        elide: Text.ElideRight
                                        font.pixelSize: Theme.fontSizeXSmall
                                        color: Theme.surfaceText
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
