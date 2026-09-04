-- Compact (classic) pangaea mainland helpers.
-- Full compact fractal/choke/margin/shift still runs in Lekmap_PangaeaPipeline when shape=compact.
-- This module is the landmass leaf for the compact maptype branch.

function LekLandmass_IsCompact()
	return (_lek_pangaea_land_shape or "compact") == "compact";
end

function LekLandmass_IsEquatorRing()
	return (_lek_pangaea_land_shape or "compact") == "equator_ring";
end
