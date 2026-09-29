mitmproxy_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$mitmproxy_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <mitmproxy_version> <build_version> [architecture]"
    echo "Example: $0 12.2.3 1 arm64"
    echo "Example: $0 12.2.3 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

# Upstream does not attach binaries to its GitHub releases; the standalone
# Linux builds are published on its own download server, keyed by the bare
# version (no "v" prefix).
UPSTREAM_URL="https://downloads.mitmproxy.org/${mitmproxy_VERSION}"

# Function to map Debian architecture to the mitmproxy release asset name.
# Upstream uses the kernel spelling (x86_64, aarch64). The binaries are
# self-contained PyInstaller builds that bundle Python and OpenSSL and only
# need glibc 2.14, so they run on every suite we target and need no library
# dependencies.
get_mitmproxy_release() {
    local arch=$1
    case "$arch" in
        "amd64") echo "mitmproxy-${mitmproxy_VERSION}-linux-x86_64" ;;
        "arm64") echo "mitmproxy-${mitmproxy_VERSION}-linux-aarch64" ;;
        *)       echo "" ;;
    esac
}

# The release tarballs contain the three binaries (mitmproxy, mitmdump,
# mitmweb) with no top-level directory, so they are always extracted into a
# directory we create.
download_release() {
    local release=$1

    rm -rf "$release" || true
    rm -f "${release}.tar.gz" || true

    if ! wget -q "${UPSTREAM_URL}/${release}.tar.gz"; then
        echo "❌ Failed to download ${release}.tar.gz"
        return 1
    fi

    mkdir -p "$release"
    if ! tar -xf "${release}.tar.gz" -C "$release"; then
        echo "❌ Failed to extract ${release}.tar.gz"
        return 1
    fi
    rm -f "${release}.tar.gz"

    for bin in mitmproxy mitmdump mitmweb; do
        if [ ! -f "$release/$bin" ]; then
            echo "❌ Unexpected tarball layout for $release (missing $bin binary)"
            return 1
        fi
        chmod +x "$release/$bin"
    done
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local mitmproxy_release

    mitmproxy_release=$(get_mitmproxy_release "$build_arch")
    if [ -z "$mitmproxy_release" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64"
        return 1
    fi

    echo "Building for architecture: $build_arch using $mitmproxy_release"

    if ! download_release "$mitmproxy_release"; then
        echo "❌ Failed to prepare mitmproxy binaries for $build_arch"
        return 1
    fi

    # Upstream ships self-contained Linux binaries for amd64/arm64 only, and
    # both work on every Ubuntu suite we target.
    declare -a arr=("jammy" "noble" "questing" "resolute")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$mitmproxy_VERSION-${BUILD_VERSION}~${dist}_${build_arch}_ubu"
        echo "  Building $FULL_VERSION"

        if ! docker build . -f Dockerfile.ubu -t "mitmproxy-ubuntu-$dist-$build_arch" \
            --build-arg UBUNTU_DIST="$dist" \
            --build-arg mitmproxy_VERSION="$mitmproxy_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg MP_RELEASE="$mitmproxy_release"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "mitmproxy-ubuntu-$dist-$build_arch")"
        if ! docker cp "$id:/mitmproxy_$FULL_VERSION.deb" - > "./mitmproxy_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./mitmproxy_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    # Clean up extracted directory
    rm -rf "$mitmproxy_release" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building mitmproxy $mitmproxy_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    # All supported architectures
    ARCHITECTURES=("amd64" "arm64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la mitmproxy_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
