//  Created by Boris Schneiderman.
//  Copyright (c) 2012-2013 The Readium Foundation.
//
//  The Readium SDK is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.


//used to report pagination state back to the host application
ReadiumSDK.Models.CurrentPagesInfo = function(spineItemCount, isFixedLayout) {

    this.isFixedLayout = isFixedLayout;
    this.spineItemCount = spineItemCount;
    this.openPages = [];

    this.addOpenPage = function(spineItemPageIndex, spineItemPageCount, idref, spineItemIndex) {
        this.openPages.push({spineItemPageIndex: spineItemPageIndex, spineItemPageCount: spineItemPageCount, idref: idref, spineItemIndex: spineItemIndex});

        this.sort();
    };

    this.sort = function() {

        this.openPages.sort(function(a, b) {

            if(a.spineItemIndex != b.spineItemIndex) {
                return a.spineItemIndex - b.spineItemIndex;
            }

            return a.pageIndex - b.pageIndex;

        });

    };

};
