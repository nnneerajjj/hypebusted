require "test_helper"
require "open3"
require "tmpdir"

class DockerEntrypointTest < ActiveSupport::TestCase
  ENTRYPOINT = Rails.root.join("bin/docker-entrypoint").to_s

  # Runs the entrypoint in a temp dir with fake ./bin/rails and ./bin/thrust,
  # so we can see whether db:prepare runs before the server starts.
  def run_entrypoint(*args)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "bin"))
      File.write(File.join(dir, "bin/rails"), "#!/bin/bash\necho \"rails $*\"\n")
      File.write(File.join(dir, "bin/thrust"), "#!/bin/bash\necho \"thrust $*\"\n")
      FileUtils.chmod(0o755, [ File.join(dir, "bin/rails"), File.join(dir, "bin/thrust") ])
      FileUtils.cp(ENTRYPOINT, File.join(dir, "docker-entrypoint"))

      output, status = Open3.capture2e("bash", "docker-entrypoint", *args, chdir: dir)
      assert status.success?, output
      output
    end
  end

  test "runs db:prepare before the server when CMD has trailing -p port" do
    output = run_entrypoint("./bin/thrust", "./bin/rails", "server", "-p", "3000")

    assert_includes output, "rails db:prepare"
    assert_includes output, "thrust ./bin/rails server -p 3000"
  end

  test "runs db:prepare when CMD is the plain server command" do
    output = run_entrypoint("./bin/thrust", "./bin/rails", "server")

    assert_includes output, "rails db:prepare"
  end

  test "does not run db:prepare for other commands" do
    output = run_entrypoint("./bin/rails", "console")

    assert_not_includes output, "db:prepare"
  end
end
