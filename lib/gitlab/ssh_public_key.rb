# frozen_string_literal: true

module Gitlab
  class SSHPublicKey
    Technology = Struct.new(:name, :key_class, :supported_sizes, :supported_algorithms)

    # See https://man.openbsd.org/sshd#AUTHORIZED_KEYS_FILE_FORMAT for the list of
    # supported algorithms.
    TECHNOLOGIES = [
      Technology.new(:rsa, SSHData::PublicKey::RSA, [1024, 2048, 3072, 4096], %w(ssh-rsa)),
      Technology.new(:dsa, SSHData::PublicKey::DSA, [1024, 2048, 3072], %w(ssh-dss)),
      Technology.new(:ecdsa, SSHData::PublicKey::ECDSA, [256, 384, 521], %w(ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521)),
      Technology.new(:ed25519, SSHData::PublicKey::ED25519, [256], %w(ssh-ed25519))
    ].freeze

    def self.technology(name)
      TECHNOLOGIES.find { |tech| tech.name.to_s == name.to_s }
    end

    def self.technology_for_key(key)
      TECHNOLOGIES.find { |tech| key.instance_of?(tech.key_class) }
    end

    def self.supported_types
      TECHNOLOGIES.map(&:name)
    end

    def self.supported_sizes(name)
      technology(name).supported_sizes
    end

    def self.supported_algorithms
      TECHNOLOGIES.flat_map { |tech| tech.supported_algorithms }
    end

    def self.supported_algorithms_for_name(name)
      technology(name).supported_algorithms
    end

    def self.sanitize(key_content)
      ssh_type, *parts = key_content.strip.split

      return key_content if parts.empty?

      parts.each_with_object(+"#{ssh_type} ").with_index do |(part, content), index|
        content << part

        if self.new(content).valid?
          break [content, parts[index + 1]].compact.join(' ') # Add the comment part if present
        elsif parts.size == index + 1 # return original content if we've reached the last element
          break key_content
        end
      end
    end

    attr_reader :key_text, :key

    def initialize(key_text)
      @key_text = key_text

      # We need to strip options to parse key with options or in known_hosts
      # format. See https://man.openbsd.org/sshd#AUTHORIZED_KEYS_FILE_FORMAT
      # and https://man.openbsd.org/sshd#SSH_KNOWN_HOSTS_FILE_FORMAT
      key_text_without_options = @key_text.to_s.match(/(\A|\s)(#{self.class.supported_algorithms.join('|')}).*/).to_s

      @key =
        begin
          SSHData::PublicKey.parse_openssh(key_text_without_options)
        rescue SSHData::DecodeError
        end
    end

    def valid?
      key.present?
    end

    def type
      technology.name if valid?
    end

    def fingerprint
      key.fingerprint(md5: true) if valid?
    end

    def fingerprint_sha256
      'SHA256:' + key.fingerprint(md5: false) if valid?
    end

    def bits
      return unless valid?

      case type
      when :rsa
        key.n.num_bits
      when :dsa
        key.p.num_bits
      when :ecdsa
        key.openssl.group.order.num_bits
      when :ed25519
        256
      end
    end

    private

    def technology
      @technology ||=
        self.class.technology_for_key(key) || raise_unsupported_key_type_error
    end

    def raise_unsupported_key_type_error
      raise("Unsupported key type: #{key.class}")
    end
  end
end
