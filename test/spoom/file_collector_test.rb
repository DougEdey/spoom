# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class FileCollectorTest < Minitest::Test
      extend T::Sig

      def test_collect_files_empty_dir
        context = Context.mktmp!

        files = collect_files(context)
        assert_empty(files)

        context.destroy!
      end

      def test_collect_files_in_root
        context = Context.mktmp!
        context.write!("a", "")
        context.write!("b.rb", "")
        context.write!("c.cpp", "")

        files = collect_files(context)
        assert_equal(["a", "b.rb", "c.cpp"], files)

        context.destroy!
      end

      def test_collect_files_in_subdirectories
        context = Context.mktmp!
        context.write!("a/a", "")
        context.write!("b/b/b", "")
        context.write!("c/c/c/c", "")
        context.write!("c/c/c/d", "")

        files = collect_files(context)
        assert_equal(["a/a", "b/b/b", "c/c/c/c", "c/c/c/d"], files)

        context.destroy!
      end

      def test_collect_files_with_allowed_extensions_only
        context = Context.mktmp!
        context.write!("a.rb", "")
        context.write!("b.rbi", "")
        context.write!("c.cpp", "")
        context.write!("d", "")

        files = collect_files(context, allow_extensions: [".rb", ".rbi"])
        assert_equal(["a.rb", "b.rbi"], files)

        context.destroy!
      end

      def test_collect_files_not_matching_excluded_patterns
        context = Context.mktmp!
        context.write!("a/a", "")
        context.write!("b/b/b", "")
        context.write!("c/c/c/c", "")
        context.write!("c/c/c/d", "")
        context.write!("c/d/e", "")
        context.write!("f/g/h.rb", "")
        context.write!("f/g/h.rbi", "")

        files = collect_files(context, exclude_patterns: ["b/**", "c/c/*", "*.rb"])
        assert_equal(["a/a", "c/d/e", "f/g/h.rbi"], files)

        context.destroy!
      end

      private

      sig do
        params(
          context: Context,
          allow_extensions: T::Array[String],
          exclude_patterns: T::Array[String],
        ).returns(T::Array[String])
      end
      def collect_files(context, allow_extensions: [], exclude_patterns: [])
        # Since we work in the context directory, we need to prefix the patterns with it
        exclude_patterns = exclude_patterns.map { |p| File.join(context.absolute_path, p) }

        collector = FileCollector.new(allow_extensions: allow_extensions, exclude_patterns: exclude_patterns)
        collector.visit_paths([context.absolute_path])

        # Since we work in the context directory, we need to remove it from the paths
        collector.files.map { |file| file.delete_prefix("#{context.absolute_path}/") }.sort
      end
    end
  end
end
