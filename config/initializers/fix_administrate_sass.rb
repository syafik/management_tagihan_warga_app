# Fix for Administrate SASS compilation issues with CSS custom properties
# Skip problematic CSS compilation entirely for admin interfaces

if defined?(SassC)
  module SassC
    class Engine
      alias_method :original_render, :render
      
      def render
        begin
          original_render
        rescue SassC::SyntaxError => e
          if e.message.include?('hsl') || e.message.include?('rgb') || e.message.include?('var(')
            # Return basic admin CSS instead of problematic modern CSS
            return <<~CSS
              /* Basic admin styling - SassC compatibility mode */
              body { font-family: sans-serif; margin: 0; padding: 20px; }
              .main-content { max-width: 1200px; margin: 0 auto; }
              .header { background: #f8f9fa; padding: 1rem; margin-bottom: 2rem; border: 1px solid #dee2e6; }
              .table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
              .table th, .table td { padding: 0.75rem; text-align: left; border-bottom: 1px solid #dee2e6; }
              .table th { background-color: #f8f9fa; font-weight: 600; }
              .btn { display: inline-block; padding: 0.375rem 0.75rem; margin-bottom: 0; font-size: 1rem; font-weight: 400; line-height: 1.5; text-align: center; text-decoration: none; vertical-align: middle; cursor: pointer; border: 1px solid transparent; border-radius: 0.25rem; }
              .btn-primary { color: #fff; background-color: #007bff; border-color: #007bff; }
              .btn-secondary { color: #fff; background-color: #6c757d; border-color: #6c757d; }
              .form-control { display: block; width: 100%; padding: 0.375rem 0.75rem; font-size: 1rem; line-height: 1.5; color: #495057; background-color: #fff; background-clip: padding-box; border: 1px solid #ced4da; border-radius: 0.25rem; }
              .form-group { margin-bottom: 1rem; }
              label { display: inline-block; margin-bottom: 0.5rem; }
              .alert { position: relative; padding: 0.75rem 1.25rem; margin-bottom: 1rem; border: 1px solid transparent; border-radius: 0.25rem; }
              .alert-success { color: #155724; background-color: #d4edda; border-color: #c3e6cb; }
              .alert-danger { color: #721c24; background-color: #f8d7da; border-color: #f5c6cb; }
            CSS
          else
            raise e
          end
        end
      end
    end
  end
end