# frozen_string_literal: true

module QA
  module Support
    module Page
      module Logging
        using Rainbow

        def assert_no_element(name)
          log("asserting no element :#{name}")

          super
        end

        def refresh(skip_finished_loading_check: false)
          log("refreshing #{current_url}")

          super
        end

        def scroll_to(selector, text: nil)
          msg = "scrolling to :#{Rainbow(selector).underline.bright}"
          msg += " with text: #{text}" if text
          log(msg)

          super
        end

        def asset_exists?(url)
          exists = super

          log("asset_exists? #{url} returned #{exists}")

          exists
        end

        def find_element(name, **kwargs)
          log("finding :#{name} with args #{kwargs}")

          element = super

          log("found :#{Rainbow(name).underline.bright}")

          element
        end

        def all_elements(name, **kwargs)
          log("finding all :#{name} with args #{kwargs}")

          elements = super

          log("found #{elements.size} :#{Rainbow(name).underline.bright}") if elements

          elements
        end

        def check_element(name, click_by_js = nil)
          log("checking :#{name}")

          super
        end

        def uncheck_element(name, click_by_js = nil)
          log("unchecking :#{name}")

          super
        end

        def click_element_coordinates(name, **kwargs)
          log(%Q(clicking the coordinates of :#{name}))

          super
        end

        def click_element(name, page = nil, **kwargs)
          msg = ["clicking :#{Rainbow(name).underline.bright}"]
          msg << ", expecting to be at #{page.class}" if page
          msg << "with args #{kwargs}"

          log(msg.compact.join(' '))

          super
        end

        def fill_element(name, content)
          masked_content = name.to_s.match?(/token|key|password/) ? '*****' : content

          log(%Q(filling :#{name} with "#{masked_content}"))

          super
        end

        def select_element(name, value)
          log(%Q(selecting "#{value}" in :#{name}))

          super
        end

        def has_element?(name, **kwargs)
          found = super

          log_has_element_or_not('has_element?', name, found, **kwargs)

          found
        end

        def has_no_element?(name, **kwargs)
          found = super

          log_has_element_or_not('has_no_element?', name, found, **kwargs)

          found
        end

        def has_text?(text, **kwargs)
          found = super

          log(%Q{has_text?('#{text}', wait: #{kwargs[:wait] || Capybara.default_max_wait_time}) returned #{found}})

          found
        end

        def has_no_text?(text, **kwargs)
          found = super

          log(%Q{has_no_text?('#{text}', wait: #{kwargs[:wait] || Capybara.default_max_wait_time}) returned #{found}})

          found
        end

        def finished_loading?(wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          log('waiting for loading to complete...')
          now = Time.now

          loaded = super

          log("loading complete after #{Time.now - now} seconds")

          loaded
        end

        def wait_for_animated_element(name)
          log("waiting for animated element: #{name}")

          super
        end

        def within_element(name, **kwargs)
          log("within element :#{name} with args #{kwargs}")

          element = super

          log("end within element :#{name} with args #{kwargs}")

          element
        end

        def within_element_by_index(name, index)
          log("within elements :#{name} at index #{index}")

          element = super

          log("end within elements :#{name} at index #{index}")

          element
        end

        private

        def log(msg)
          QA::Runtime::Logger.debug(msg)
        end

        def log_has_element_or_not(method, name, found, **kwargs)
          msg = ["#{method} :#{Rainbow(name).underline.bright}"]
          msg << %Q(with text "#{kwargs[:text]}") if kwargs[:text]
          msg << "class: #{kwargs[:class]}" if kwargs[:class]
          msg << "(wait: #{kwargs[:wait] || Capybara.default_max_wait_time})"
          msg << "returned: #{found}"

          log(msg.compact.join(' '))
        end
      end
    end
  end
end
