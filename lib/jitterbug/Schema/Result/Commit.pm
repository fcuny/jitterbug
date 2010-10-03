package jitterbug::Schema::Result::Commit;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);

__PACKAGE__->table('commit_push');
__PACKAGE__->add_columns(
    sha256 => {
        data_type         => 'text',
        is_auto_increment => 0,
    },
    content   => { data_type => 'text', },
    projectid => {
        data_type      => 'int',
        is_foreign_key => 1,
    },
    timestamp => { data_type => 'datetime' },
);
__PACKAGE__->set_primary_key('sha256');
__PACKAGE__->belongs_to(
    project => 'jitterbug::Schema::Result::Project',
    'projectid'
);
__PACKAGE__->has_many(
    tasks => 'jitterbug::Schema::Result::Task',
    'taskid',
);

1;
