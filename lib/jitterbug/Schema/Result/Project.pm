package jitterbug::Schema::Result::Project;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('project');
__PACKAGE__->add_columns(
    projectid => {
        data_type         => 'int',
        is_auto_increment => 1,
    },
    name        => { data_type => 'text', },
    url         => { data_type => 'text', },
    description => { data_type => 'text', },
    owner       => { data_type => 'text', }
);
__PACKAGE__->set_primary_key('projectid');
__PACKAGE__->add_unique_constraint( [qw/name/] );
__PACKAGE__->has_many(
    commits => 'jitterbug::Schema::Result::Commit',
    'sha256',
);
__PACKAGE__->has_many(
    tasks => 'jitterbug::Schema::Result::Task',
    'taskid',
);

1;
