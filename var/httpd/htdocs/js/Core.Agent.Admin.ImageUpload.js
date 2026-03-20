// --
// OTOBO is a web-based ticketing system for service organisations.
// --
// Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
// Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
// --
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace Core.Agent.Admin.ImageUpload
 * @memberof Core.Agent.Admin
 * @author
 * @description
 *      This namespace contains the special module function for ImageUpload module.
 */
 Core.Agent.Admin.ImageUpload = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.Admin.ImageUpload
     * @function
     * @description
     *      This function initializes the table filter.
     */
    TargetNS.Init = function () {
        Core.UI.Table.InitTableFilter($("#FilterImages"), $("#Images"));

        // delete image
        TargetNS.InitImageDelete();
    };

    /**
     * @name ImageDelete
     * @memberof Core.Agent.Admin.ImageUpload
     * @function
     * @description
     *      This function deletes image on buton click.
     */
    TargetNS.InitImageDelete = function () {
        $('.ImageDelete').on('click', function () {
            var $ImageDeleteElement = $(this);

            Core.UI.Dialog.ShowContentDialog(
                $('#DeleteImageDialogContainer'),
                Core.Language.Translate('Delete this Image'),
                '240px',
                'Center',
                true,
                [
                    {
                        Class: 'Primary',
                        Label: Core.Language.Translate("Confirm"),
                        Function: function() {
                            $('.Dialog .InnerContent .Center').text(Core.Language.Translate("Deleting image..."));
                            $('.Dialog .Content .ContentFooter').remove();

                            Core.AJAX.FunctionCall(
                                Core.Config.Get('Baselink') + 'Action=AdminImageUpload;Subaction=Delete',
                                { ID: $ImageDeleteElement.data('id') },
                                function(Reponse) {
                                    var DialogText = Core.Language.Translate("There was an error deleting the image. Please check the logs for more information.");
                                    if (parseInt(Reponse, 10) > 0) {
                                        $('#ImageID_' + parseInt(Reponse, 10)).fadeOut(function() {
                                            $(this).remove();
                                        });
                                        DialogText = Core.Language.Translate("Image was deleted successfully.");
                                    }
                                    $('.Dialog .InnerContent .Center').text(DialogText);
                                    window.setTimeout(function() {
                                        Core.UI.Dialog.CloseDialog($('.Dialog:visible'));
                                    }, 1000);
                                }
                            );
                        }
                    },
                    {
                        Label: Core.Language.Translate("Cancel"),
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('#DeleteImageDialog'));
                        }
                    }
                ]
            );
            return false;
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
 }(Core.Agent.Admin.ImageUpload || {}));
