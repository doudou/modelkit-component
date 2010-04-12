#ifndef <%= component.name %>_USER_MARSHALLING_HH
#define <%= component.name %>_USER_MARSHALLING_HH

#include <<%= component.name %>ToolkitTypes.hpp>

namespace <%= component.name %>
{
    <% toolkit.opaques.find_all { |op| op.generate_templates? }.each do |opaque_def|
        from = opaque_def.type
        into = component.find_type(opaque_def.intermediate)
        if opaque_def.needs_copy? %>
    /** Converts \c real_type into \c intermediate */
    void to_intermediate(<%= into.ref_type %> intermediate, <%= from.arg_type %> real_type);
    /** Converts \c intermediate into \c real_type */
    void from_intermediate(<%= from.ref_type %> real_type, <%= into.arg_type %> intermediate);
        <% else %>
    /** Returns the intermediate value that is contained in \c real_type */
    <%= into.arg_type %> to_intermediate(<%= from.arg_type %> real_type);
    /** Stores \c intermediate into \c real_type. \c intermediate is owned by \c
     * real_type afterwards. */
    bool from_intermediate(<%= from.ref_type %> real_type, <%= into.cxx_name %>* intermediate);
    /** Release ownership of \c real_type on the corresponding intermediate
     * pointer.
     */
    void release(<%= from.ref_type %> real_type);
        <% end %>
    <% end %>
}

#endif

