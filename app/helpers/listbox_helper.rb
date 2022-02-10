# frozen_string_literal: true

module ListboxHelper
  DROPDOWN_CONTAINER_CLASSES = %w[dropdown b-dropdown gl-new-dropdown btn-group js-redirect-listbox].freeze
  DROPDOWN_BUTTON_CLASSES = %w[btn dropdown-toggle btn-default btn-md gl-button gl-dropdown-toggle].freeze
  DROPDOWN_INNER_CLASS = 'gl-new-dropdown-button-text'
  DROPDOWN_ICON_CLASS = 'gl-button-icon dropdown-chevron gl-icon'

  # Creates a listbox component with redirect behavior.
  #
  # Use this for migrating existing deprecated dropdowns to become
  # Pajamas-compliant. New features should use Vue components directly instead.
  #
  # The `items` parameter must be an array of hashes, each with `value`, `text`
  # and `href` keys, where `value` is a unique identifier for the item (e.g.,
  # the sort key), `text` is the user-facing string for the item, and `href` is
  # the path to redirect to when that item is selected.
  #
  # The `selected` parameter is the currently selected `value`, and must
  # correspond to one of the `items`, or be `nil`. When `selected.nil?`, the first item is selected.
  #
  # The final parameter `html_options` applies arbitrary attributes to the
  # returned tag. Some of these are passed to the underlying Vue component as
  # props, e.g., to right-align the menu of items, add `data: { right: true }`.
  #
  # Examples:
  #   # Create a listbox with two items, with the first item selected
  #   - items = [{ value: 'foo', text: 'Name, ascending', href: '/foo' },
  #              { value: 'bar', text: 'Name, descending', href: '/bar' }]
  #   = gl_redirect_listbox_tag items, 'foo'
  #
  #   # Create the same listbox, right-align the menu and add margin styling
  #   = gl_redirect_listbox_tag items, 'foo', class: 'gl-ml-3', data: { right: true }
  def gl_redirect_listbox_tag(items, selected, html_options = {})
    # Add script tag for app/assets/javascripts/entrypoints/behaviors/redirect_listbox.js
    content_for :page_specific_javascripts do
      webpack_bundle_tag 'redirect_listbox'
    end

    selected ||= items.first[:value]
    selected_option = items.find { |opt| opt[:value] == selected }
    raise ArgumentError, "cannot find #{selected} in #{items}" unless selected_option

    button = button_tag(type: :button, class: DROPDOWN_BUTTON_CLASSES) do
      content_tag(:span, selected_option[:text], class: DROPDOWN_INNER_CLASS) +
        sprite_icon('chevron-down', css_class: DROPDOWN_ICON_CLASS)
    end

    classes = [*DROPDOWN_CONTAINER_CLASSES, *html_options[:class]]
    data = { items: items, selected: selected }.merge(html_options[:data] || {})

    content_tag(:div, button, html_options.merge({
      class: classes,
      data: data
    }))
  end
end
