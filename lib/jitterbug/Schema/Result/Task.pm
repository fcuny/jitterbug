package jitterbug::Schema::Result::Task;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('task');
__PACKAGE__->add_columns(
    taskid => {
        data_type         => 'int',
        is_auto_increment => 1,
    },
    sha256    => { data_type => 'text', is_foreign_key => 1 },
    projectid => {
        data_type      => 'int',
        is_foreign_key => 1,
    },
    running => {
        data_type => 'bool',
        default_value   => 0,
    },
);

__PACKAGE__->set_primary_key('taskid');
__PACKAGE__->add_unique_constraint( [qw/projectid/] );
__PACKAGE__->add_unique_constraint( [qw/sha256/] );
__PACKAGE__->belongs_to(
    project => 'jitterbug::Schema::Result::Project',
    'projectid'
);
__PACKAGE__->belongs_to(
    commit => 'jitterbug::Schema::Result::Commit',
    'sha256'
);

1;
