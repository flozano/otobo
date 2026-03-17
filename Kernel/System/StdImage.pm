# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::System::StdImage;

use strict;
use warnings;

use MIME::Base64;

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Encode',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::StdImage - standard image lib

=head1 DESCRIPTION

All standard image functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $StdImageObject = $Kernel::OM->Get('Kernel::System::StdImage');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'StdImage';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=head2 StdImageAdd()

create a new standard image

    my $ID = $StdImageObject->StdImageAdd(
        Name        => 'Some Name',
        ValidID     => 1,
        Content     => $Content,
        ContentType => 'image/png',
        Filename    => 'SomeFile.png',
        UserID      => 123,
    );

=cut

sub StdImageAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Name ValidID Content ContentType Filename UserID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # encode image if it's a postgresql backend!!!
    # if ( !$DBObject->GetDatabaseFunction('DirectBlob') ) {
    #     $Kernel::OM->Get('Kernel::System::Encode')->EncodeOutput( \$Param{Content} );
    #     $Param{Content} = encode_base64( $Param{Content} );
    # }

    # insert image
    return if !$DBObject->Do(
        SQL => 'INSERT INTO standard_image '
            . ' (name, content_type, content, filename, valid_id, comments, '
            . ' create_time, create_by, change_time, change_by) VALUES '
            . ' (?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name},    \$Param{ContentType}, \$Param{Content}, \$Param{Filename},
            \$Param{ValidID}, \$Param{Comment},     \$Param{UserID},  \$Param{UserID},
        ],
    );

    # get the id
    $DBObject->Prepare(
        SQL  => 'SELECT id FROM standard_image WHERE name = ? AND content_type = ?',
        Bind => [ \$Param{Name}, \$Param{ContentType}, ],
    );

    # fetch the result
    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return $ID;
}

=head2 StdImageGet()

get a standard image

    my %Data = $StdImageObject->StdImageGet(
        ID => $ID,
    );

=cut

sub StdImageGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # sql
    return if !$DBObject->Prepare(
        SQL => 'SELECT name, content_type, content, filename, valid_id, comments, '
            . 'create_time, create_by, change_time, change_by '
            . 'FROM standard_image WHERE id = ?',
        Bind   => [ \$Param{ID} ],
        Encode => [ 1, 1, 0, 1, 1, 1 ],
    );

    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        # decode image if it's a postgresql backend!!!
        # if ( !$DBObject->GetDatabaseFunction('DirectBlob') ) {
        #     $Row[2] = decode_base64( $Row[2] );
        # }
        %Data = (
            ID          => $Param{ID},
            Name        => $Row[0],
            ContentType => $Row[1],
            Content     => $Row[2],
            Filename    => $Row[3],
            ValidID     => $Row[4],
            Comment     => $Row[5],
            CreateTime  => $Row[6],
            CreateBy    => $Row[7],
            ChangeTime  => $Row[8],
            ChangeBy    => $Row[9],
        );
    }

    return %Data;
}

=head2 StdImageUpdate()

update a new standard image

    my $ID = $StdImageObject->StdImageUpdate(
        ID          => $ID,
        Name        => 'Some Name',
        ValidID     => 1,
        Content     => $Content,
        ContentType => 'image/png',
        Filename    => 'SomeFile.png',
        UserID      => 123,
    );

=cut

sub StdImageUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ID Name ValidID UserID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    # reset cache
    my %Data = $Self->StdImageGet(
        ID => $Param{ID},
    );

    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'StdImageLookupID::' . $Data{ID},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'StdImageLookupName::' . $Data{Name},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'StdImageLookupID::' . $Param{ID},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'StdImageLookupName::' . $Param{Name},
    );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update image
    return if !$DBObject->Do(
        SQL => 'UPDATE standard_image SET name = ?, comments = ?, valid_id = ?, '
            . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name},    \$Param{Comment},
            \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    if ( $Param{Content} ) {

        # encode image if it's a postgresql backend!!!
        # if ( !$DBObject->GetDatabaseFunction('DirectBlob') ) {
        #     $Kernel::OM->Get('Kernel::System::Encode')->EncodeOutput( \$Param{Content} );
        #     $Param{Content} = encode_base64( $Param{Content} );
        # }

        return if !$DBObject->Do(
            SQL => 'UPDATE standard_image SET content = ?, content_type = ?, '
                . ' filename = ? WHERE id = ?',
            Bind => [
                \$Param{Content}, \$Param{ContentType}, \$Param{Filename}, \$Param{ID},
            ],
        );
    }

    return 1;
}

=head2 StdImageDelete()

delete a standard image

    $StdImageObject->StdImageDelete(
        ID => $ID,
    );

=cut

sub StdImageDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(ID)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!",
            );
            return;
        }
    }

    # reset cache
    my %Data = $Self->StdImageGet(
        ID => $Param{ID},
    );

    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'StdImageLookupID::' . $Param{ID},
    );
    $Kernel::OM->Get('Kernel::System::Cache')->Delete(
        Type => $Self->{CacheType},
        Key  => 'StdImageLookupName::' . $Data{Name},
    );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # delete attachment<->std template relation
    # return if !$DBObject->Do(
    #     SQL  => 'DELETE FROM standard_template_attachment WHERE standard_attachment_id = ?',
    #     Bind => [ \$Param{ID} ],
    # );

    # sql
    return if !$DBObject->Do(
        SQL  => 'DELETE FROM standard_image WHERE ID = ?',
        Bind => [ \$Param{ID} ],
    );

    return 1;
}

=head2 StdImageLookup()

lookup for a standard image

    my $ID = $StdImageObject->StdImageLookup(
        StdImage => 'Some Name',
    );

    my $Name = $StdImageObject->StdImageLookup(
        StdImageID => $ID,
    );

=cut

sub StdImageLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{StdImage} && !$Param{StdImageID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Got no StdImage or StdImage!',
        );
        return;
    }

    # check if we ask the same request?
    my $CacheKey;
    my $Key;
    my $Value;
    if ( $Param{StdImageID} ) {
        $CacheKey = 'StdImageLookupID::' . $Param{StdImageID};
        $Key      = 'StdImageID';
        $Value    = $Param{StdImageID};
    }
    else {
        $CacheKey = 'StdImageLookupName::' . $Param{StdImage};
        $Key      = 'StdImage';
        $Value    = $Param{StdImage};
    }

    my $Cached = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type           => $Self->{CacheType},
        Key            => $CacheKey,
        CacheInMemory  => 1,
        CacheInBackend => 0,
    );

    return $Cached if $Cached;

    # get data
    my $SQL;
    my @Bind;
    if ( $Param{StdImage} ) {
        $SQL = 'SELECT id FROM standard_image WHERE name = ?';
        push @Bind, \$Param{StdImage};
    }
    else {
        $SQL = 'SELECT name FROM standard_image WHERE id = ?';
        push @Bind, \$Param{StdImageID};
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    $DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    my $DBValue;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $DBValue = $Row[0];
    }

    # check if data exists
    if ( !$DBValue ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Found no $Key found for $Value!",
        );
        return;
    }

    # cache result
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type           => $Self->{CacheType},
        TTL            => $Self->{CacheTTL},
        Key            => $CacheKey,
        Value          => $DBValue,
        CacheInMemory  => 1,
        CacheInBackend => 0,
    );

    return $DBValue;
}

=head2 StdImageList()

get list of standard images - return a hash (ID => Name (Filename))

    my %List = $StdImageObject->StdImageList(
        Valid => 0,  # optional, defaults to 1
    );

returns:

        %List = (
          '1' => 'Some Name' ( Filname ),
          '2' => 'Some Name' ( Filname ),
          '3' => 'Some Name' ( Filname ),
    );

=cut

sub StdImageList {
    my ( $Self, %Param ) = @_;

    # set default value
    my $Valid = $Param{Valid} // 1;

    # create the valid list
    my $ValidIDs = join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();

    # build SQL
    my $SQL = 'SELECT id, name, filename FROM standard_image';

    # add WHERE statement in case Valid param is set to '1', for valid StdImage
    if ($Valid) {
        $SQL .= ' WHERE valid_id IN (' . $ValidIDs . ')';
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get data from database
    return if !$DBObject->Prepare(
        SQL => $SQL,
    );

    # fetch the result
    my %StdImageList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $StdImageList{ $Row[0] } = "$Row[1] ( $Row[2] )";
    }

    return %StdImageList;
}

1;
