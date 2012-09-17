module GLI
  module Commands
    module HelpModules
      # Handles wrapping text
      class ArgNameFormatter
        def format(arguments_description,arguments_options)
          return '' if String(arguments_description).strip == ''
          desc = arguments_description
          if arguments_options.include? :optional
            desc = "[#{desc}]"
          end
          if arguments_options.include? :multiple
            desc = "#{desc}[, #{desc}]*"
          end
          " " + desc
        end
      end
    end
  end
end
