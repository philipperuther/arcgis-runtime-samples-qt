// [WriteFile Name=SearchDictionarySymbolStyle, Category=Search]
// [Legal]
// Copyright 2016 Esri.

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
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import Esri.ArcGISRuntime 100.1
import Esri.ArcGISExtras 1.1

Rectangle {
    id: rootRectangle
    clip: true

    width: 800
    height: 600

    property real scaleFactor: System.displayScaleFactor

    property double fontSize: 16 * scaleFactor
    property var repeaterModel: ["Names", "Tags", "Symbol Classes", "Categories", "Keys"]
    property var hintsModel: ["Fire", "Sustainment Points", "3", "Control Measure", "25212300_6"]
    property var searchParamList: [[],[],[],[],[]]

    property url dataPath: System.userHomePath + "/ArcGIS/Runtime/Data/styles/mil2525d.stylx"

    DictionarySymbolStyle {
        id: dictionarySymbolStyle
        specificationType: "mil2525d"
        styleLocation: dataPath

        //Search completed
        onSearchSymbolsStatusChanged:{
            if (searchSymbolsStatus !== Enums.TaskStatusCompleted)
                return;

            seachBtn.enabled = true;
            resultView.visible = true;

            //Update the number of results retuned
            resultText.text = "Result(s) found: " + searchSymbolsResult.count
        }
    }

    SymbolStyleSearchParameters {
        id: searchParams
    }

    Rectangle {
        id: topRectangle
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: hideSearch.checked ?  searchRow.height + resultText.height + (20 * scaleFactor) :
                                     fieldColumn.childrenRect.height + (20 * scaleFactor)
        width: parent.width *.9

        Column {
            id: fieldColumn
            anchors {
                fill: parent
                margins: 8 * scaleFactor
            }

            spacing: 4 * scaleFactor

            Repeater {
                id: repeater
                model: repeaterModel

                Rectangle {
                    width: parent.width
                    height: hideSearch.checked ? 0 : 72 * scaleFactor
                    color: "lightgrey"
                    border.color: "darkgrey"
                    radius: 4
                    clip: true

                    Text {
                        id: categoryTitle
                        anchors {
                            top: parent.top
                            left: parent.left
                            margins: 8 * scaleFactor
                        }
                        height: categoryEntry.height
                        width: 66 * scaleFactor
                        text: repeaterModel[index]
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.WordWrap
                    }

                    Button {
                        id: addCategoryButton
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: 8 * scaleFactor
                        }
                        height: categoryEntry.height
                        width: height
                        iconSource: enabled ? "qrc:/Samples/Search/SearchDictionarySymbolStyle/ic_menu_addencircled_light.png" :
                                              "qrc:/Samples/Search/SearchDictionarySymbolStyle/ic_menu_addencircled_dark.png"
                        enabled: categoryEntry.text.length > 0

                        onClicked: {
                            if (categoryEntry.text.length === 0)
                                return;

                            var tmp = searchParamList;
                            tmp[index].push(categoryEntry.text);

                            searchParamList = tmp
                            categoryEntry.text = "";
                            seachBtn.enabled = true;
                        }
                    }

                    Button {
                        id: clearCategoryButton
                        anchors {
                            top: addCategoryButton.bottom
                            right: parent.right
                            margins: 8 * scaleFactor
                        }
                        height: categoryEntry.height
                        width: height
                        iconSource: enabled ? "qrc:/Samples/Search/SearchDictionarySymbolStyle/ic_menu_closeclear_light.png" :
                                              "qrc:/Samples/Search/SearchDictionarySymbolStyle/ic_menu_closeclear_dark.png"
                        enabled: categoryList.text.length > 0

                        onClicked: {
                            categoryEntry.text = "";
                            var tmp = searchParamList;
                            tmp[index] = [];

                            searchParamList = tmp;
                        }
                    }

                    TextField {
                        id: categoryEntry
                        anchors {
                            top: parent.top
                            right: addCategoryButton.left
                            left: categoryTitle.right
                            margins: 8 * scaleFactor
                        }
                        placeholderText: repeaterModel[index] +" (e.g. "+ hintsModel[index] +")"
                        validator: RegExpValidator{ regExp: /^\s*[\da-zA-Z][\da-zA-Z\s]*$/ }
                        onAccepted:  addCategoryButton.clicked();
                    }

                    Label {
                        id: categoryList
                        anchors {
                            top: categoryEntry.bottom
                            right: parent.right
                            left: parent.left
                            margins: 8 * scaleFactor
                        }
                        height: 32 * scaleFactor
                        text: searchParamList[index].length > 0 ? searchParamList[index].join() : ""
                    }
                }
            }

            Row {
                id: searchRow
                anchors {
                    margins: 10 * scaleFactor
                }
                spacing: 10 * scaleFactor

                Button {
                    id: seachBtn
                    width: 100 * scaleFactor
                    height: 32 * scaleFactor
                    enabled: false
                    text: "Search"
                    iconSource: enabled ? "qrc:/Samples/Search/SearchDictionarySymbolStyle/ic_menu_find_light.png" :
                                          "qrc:/Samples/Search/SearchDictionarySymbolStyle/ic_menu_find_dark.png"

                    onClicked: {
                        //Disable the search button and start the search
                        enabled = false;
                        resultView.visible = false;

                        searchParams.names = searchParamList[0];
                        searchParams.symbolClasses = searchParamList[1];
                        searchParams.categories = searchParamList[2];
                        searchParams.keys = searchParamList[3];

                        dictionarySymbolStyle.searchSymbols(searchParams);
                    }
                }

                Button {
                    text: "Clear"
                    height: seachBtn.height
                    enabled: resultView.count > 0
                    style: seachBtn.style
                    onClicked: {
                        //Set the results visibility to false
                        resultView.visible = false;
                        //Reset the search parameters
                        searchParamList = [[],[],[],[],[]];
                    }
                }

                Button {
                    id: hideSearch
                    height: seachBtn.height
                    checked: false
                    checkable: true
                    iconSource: checked ? "qrc:/Samples/Search/SearchDictionarySymbolStyle/ic_menu_collapsed_light.png" :
                                          "qrc:/Samples/Search/SearchDictionarySymbolStyle/ic_menu_expanded_light.png"
                }
            }

            Text {
                id: resultText
                visible: resultView.visible
                text: "Result(s) found: " + resultView.count
                font.pixelSize: fontSize
            }
        }
    }

    Rectangle {
        id: bottomRectangle
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            top: topRectangle.bottom
        }
        width: parent.width

        //Listview of results returned from Dictionary
        ListView {
            id: resultView
            anchors {
                fill: parent
                margins: 10 * scaleFactor
            }
            spacing: 20 * scaleFactor

            clip: true
            model: dictionarySymbolStyle.searchSymbolsResult

            delegate: Component {
                Row {
                    anchors {
                        margins: 20 * scaleFactor
                    }
                    width: resultView.width
                    spacing: 10 * scaleFactor

                    Image {
                        source: symbolUrl
                    }

                    Column {
                        width: parent.width
                        spacing: 10 * scaleFactor

                        Text {
                            id: nameText
                            text: "Name: " + name
                            font.pixelSize: fontSize
                            width: parent.width
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            text: "Tags: " + tags
                            font.pixelSize: fontSize
                            width: nameText.width
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            text: "SymbolClass: " + symbolClass
                            font.pixelSize: fontSize
                            width: nameText.width
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            text: "Category: " + category
                            font.pixelSize: fontSize
                            width: nameText.width
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        Text {
                            text: "Key: " + key
                            font.pixelSize: fontSize
                            width: nameText.width
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }
                    }
                }
            }
        }
    }

    // Neatline rectangle
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border {
            width: 0.5 * scaleFactor
            color: "black"
        }
    }
}