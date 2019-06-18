// [WriteFile Name=IntegratedWindowsAuthentication, Category=CloudAndPortal]
// [Legal]
// Copyright 2019 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// [Legal]

import QtQuick 2.6
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Esri.ArcGISRuntime 100.6
import Esri.ArcGISRuntime.Toolkit.Dialogs 100.6

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    readonly property url arcgis_url: "http://www.arcgis.com"
    property var portalItem

    MapView {
        id: mapView
        anchors.fill: parent

        Map {
            BasemapTopographic {}
        }
    }

    Portal {
        id: publicPortal

        onLoadStatusChanged: {
            console.log("loading public");
            if (loadStatus === Enums.LoadStatusFailedToLoad)
                retryLoad();

            if (loadStatus !== Enums.LoadStatusLoaded) {
                return;
            }
        }


    }

    Component {
        id: webmapDelegate
        Rectangle {
            height: childrenRect.height
            width: childrenRect.width
            color: "#00000000"
            Text {
                id: outputString
                text: title
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: webmapsList.currentIndex = index;
                onDoubleClicked: loadSelectedWebmap(webmapsList.model.get(index));
            }
        }
    }

    Rectangle {
        id: portalLayoutRect
        anchors {
            margins: 5
            horizontalCenter: parent.horizontalCenter
            top: parent.top
        }
        width: childrenRect.width
        height: childrenRect.height * 2.2
        color: "#000000"
        opacity: .75
        radius: 5

        ColumnLayout {
            TextField {
                id: securePortalUrl
                Layout.fillWidth: true
                Layout.margins: 3
                text: qsTr("Enter portal url")
            }

            Row {
                Layout.fillWidth: true
                Layout.margins: 3
                spacing: 4
                Button {
                    id: searchPublic
                    text: qsTr("Search Public")
                    onClicked: {
                        searchPortal(arcgis_url);
                    }
                }
                Button {
                    id: searchSecure
                    text: qsTr("Search Secure")
                    //onClicked: //do something
                }
            }

            //use listview or repeater if it doesn't work
            ListView {
                id: webmapsList
                width: childrenRect.width
                height: childrenRect.height
                Layout.margins: 3
                model: null
                delegate: webmapDelegate
            }
        }
    }

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        running: publicPortal.loadStatus == Enums.LoadStatusLoading
    }

    PortalQueryParametersForItems {
        id: webmapQuery
        types: [ Enums.PortalItemTypeWebMap ]
    }

    function searchPortal (portalUrl) {
        var pubPortal = ArcGISRuntimeEnvironment.createObject("Portal", {url: portalUrl});
        pubPortal.loadStatusChanged.connect(function() {
            if (pubPortal.loadStatus === Enums.LoadStatusFailedToLoad)
                pubPortal.retryLoad();

            if (pubPortal.loadStatus === Enums.LoadStatusLoaded){
                indicator.running = false;
                pubPortal.findItems(webmapQuery);
                return;
            }

        });

        pubPortal.findItemsStatusChanged.connect(function() {

            if ( pubPortal.findItemsStatus === Enums.TaskStatusCompleted ) {
                console.log("signal exists");
                webmapsList.model = pubPortal.findItemsResult.itemResults;
            }

        });
        pubPortal.load();
        indicator.running = true;
    }

    function loadSelectedWebmap(selectedWebmap) {
        portalItem = selectedWebmap;

        portalItem.loadStatusChanged.connect(createMap);
        portalItem.loadErrorChanged.connect( function() {
            webMapMsg.text = portalItem.loadError.message;
            webMapMsg.visible = true;
        });

        portalItem.load();
    }

    function createMap() {
        if (portalItem.loadStatus !== Enums.LoadStatusLoaded)
            return;

        mapView.map = ArcGISRuntimeEnvironment.createObject("Map", {"item": portalItem});

        mapView.map.loadStatusChanged.connect(assignWebmap);
        mapView.map.loadErrorChanged.connect( function() {
            webMapMsg.text = mapView.map.loadError.message;
            webMapMsg.visible = true;
        });

        mapView.map.load();
    }

    function assignWebmap() {
        if (mapView.map.loadStatus !== Enums.LoadStatusLoaded)
            return;

        //webmapsList.visible = false;
        mapView.visible = true;
    }


    // Uncomment this section when running as standalone application
    AuthenticationView {
        id: authView
        authenticationManager: AuthenticationManager
    }

    //! [PortalUserInfo create portal]

    Dialog {
        id: webMapMsg
        modal: true
        x: Math.round(parent.width - width) / 2
        y: Math.round(parent.height - height) / 2
        standardButtons: Dialog.Ok
        title: "Could not load web map!"
        property alias text : textLabel.text
        Text {
            id: textLabel
        }
        onAccepted: visible = false;
    }
}
